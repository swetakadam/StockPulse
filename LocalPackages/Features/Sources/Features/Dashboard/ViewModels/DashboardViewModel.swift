//
//  DashboardViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import Combine
import OSLog

// MARK: - MarketIndex

public struct MarketIndex: Identifiable {
    public let id: String
    public let name: String
    public let value: Double
    public let change: Double
    public let changePercent: Double

    public init(id: String, name: String, value: Double, change: Double, changePercent: Double) {
        self.id = id
        self.name = name
        self.value = value
        self.change = change
        self.changePercent = changePercent
    }

    public static let mockSP500  = MarketIndex(id: "SP500",  name: "S&P 500",  value: 5218.19,  change:  23.45,  changePercent:  0.45)
    public static let mockNASDAQ = MarketIndex(id: "NASDAQ", name: "NASDAQ",   value: 16379.46, change: -45.23,  changePercent: -0.28)
    public static let mockDOW    = MarketIndex(id: "DOW",    name: "DOW",      value: 39069.11, change:  125.65, changePercent:  0.32)
    public static let mockList   = [mockSP500, mockNASDAQ, mockDOW]
}

// MARK: - Protocol

public protocol DashboardViewModelProtocol: ObservableObject {
    var marketIndices:   [MarketIndex] { get }
    var trendingStocks:  [Stock]       { get }
    var watchlistStocks: [Stock]       { get }
    var topGainers:      [Stock]       { get }
    var topLosers:       [Stock]       { get }
    var isLoading:       Bool          { get }
    var error:           String?       { get }
    @MainActor func loadDashboard()    async
    @MainActor func refreshDashboard() async
}

// MARK: - ViewModel

public final class DashboardViewModel: ObservableObject, DashboardViewModelProtocol {

    private let fetchStockUseCase:     any FetchStockUseCaseProtocol
    private let fetchWatchlistUseCase: any FetchWatchlistUseCaseProtocol
    private let cache:                 any StockCacheProtocol
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Dashboard")
    
    @Published public private(set) var marketIndices:   [MarketIndex] = MarketIndex.mockList
    @Published public private(set) var trendingStocks:  [Stock]       = []
    @Published public private(set) var watchlistStocks: [Stock]       = []
    @Published public private(set) var topGainers:      [Stock]       = []
    @Published public private(set) var topLosers:       [Stock]       = []
    @Published public private(set) var isLoading:       Bool          = false
    @Published public private(set) var error:           String?

    private let trendingSymbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA", "META", "BRK.B"]
    private let gainerSymbols   = ["JPM", "V", "MA", "BAC", "WFC"]
    private let loserSymbols    = ["INTC", "IBM", "HPQ", "DELL", "NOK"]

    public init(
        fetchStockUseCase:     any FetchStockUseCaseProtocol,
        fetchWatchlistUseCase: any FetchWatchlistUseCaseProtocol,
        cache:                 any StockCacheProtocol
    ) {
        self.fetchStockUseCase     = fetchStockUseCase
        self.fetchWatchlistUseCase = fetchWatchlistUseCase
        self.cache                 = cache
    }

    // MARK: - Public

    /// Prevents reloading when switching tabs.
    /// Cache layer handles data freshness.
    /// Pull-to-refresh bypasses this via refreshDashboard().
    private var hasLoadedOnce = false

    @MainActor
    public func loadDashboard() async {
        guard !isLoading, !hasLoadedOnce else { return }
        hasLoadedOnce = true
        isLoading = true
        error = nil

        // Phase 1: Populate from cache instantly — silent, no spinner change
        await loadFromCacheInstantly()

        // If cache had data — hide spinner now.
        // Phase 2 will update arrays quietly in background.
        if !trendingStocks.isEmpty {
            isLoading = false
        }

        // Phase 2: Fetch network for any cache misses.
        // UI already showing cached data — updates arrive silently.
        if policy.useConcurrentFetching {
            // Premium tier: all groups concurrent
            async let t = fetchStocks(symbols: trendingSymbols)
            async let g = fetchStocks(symbols: gainerSymbols)
            async let l = fetchStocks(symbols: loserSymbols)
            async let w = fetchWatchlistStocks()
            let (trending, gainers, losers, watchlist) = await (t, g, l, w)
            trendingStocks  = trending
            topGainers      = gainers
            topLosers       = losers
            watchlistStocks = watchlist
        } else {
            // Free tier: sequential — stocks update one by one as
            // network responses arrive. No spinner — data already visible.
            trendingStocks  = await fetchStocks(symbols: trendingSymbols)
            topGainers      = await fetchStocks(symbols: gainerSymbols)
            topLosers       = await fetchStocks(symbols: loserSymbols)
            watchlistStocks = await fetchWatchlistStocks()
        }

        let trendingCount  = trendingStocks.count
        let gainersCount   = topGainers.count
        let losersCount    = topLosers.count
        let watchlistCount = watchlistStocks.count
        logger.debug("📊 Trending count: \(trendingCount)")
        logger.debug("📊 Gainers count: \(gainersCount)")
        logger.debug("📊 Losers count: \(losersCount)")
        logger.debug("📊 Watchlist count: \(watchlistCount)")

        if trendingStocks.isEmpty && topGainers.isEmpty && topLosers.isEmpty {
            error = "Unable to load market data. Please check your connection."
        }

        // Always false when fully done — covers case where Phase 1
        // cache was empty and spinner stayed visible through Phase 2.
        isLoading = false
    }

    /// Pull-to-refresh — forces fresh network data.
    /// Invalidates ALL cached stocks so Phase 1 finds nothing
    /// and Phase 2 fetches everything from network.
    @MainActor
    public func refreshDashboard() async {
        cache.invalidateAll()  // clear cache so network is forced
        hasLoadedOnce = false
        isLoading = false
        await loadDashboard()
    }

    // MARK: - Stock Fetching

    private let policy: CachePolicy = .current

    /// Phase 1: Populate arrays from cache only — no network calls.
    /// Does NOT touch isLoading — spinner state managed by loadDashboard().
    /// Completes in microseconds for warm cache.
    @MainActor
    private func loadFromCacheInstantly() async {
        // Use concurrent async let — all from memory/disk, no network
        async let t = fetchStocks(symbols: trendingSymbols)
        async let g = fetchStocks(symbols: gainerSymbols)
        async let l = fetchStocks(symbols: loserSymbols)
        async let w = fetchWatchlistStocks()
        let (trending, gainers, losers, watchlist) = await (t, g, l, w)

        trendingStocks  = trending
        topGainers      = gainers
        topLosers       = losers
        watchlistStocks = watchlist
    }

    private func fetchStocks(symbols: [String]) async -> [Stock] {
        policy.useConcurrentFetching
            ? await fetchStocksConcurrently(symbols: symbols)
            : await fetchStocksSequentially(symbols: symbols)
    }

    /// Premium tier: concurrent fetching with TaskGroup.
    /// Fast but hits rate limits on free tier.
    private func fetchStocksConcurrently(symbols: [String]) async -> [Stock] {
        await withTaskGroup(of: (Int, Stock?).self) { group in
            for (index, symbol) in symbols.enumerated() {
                group.addTask { [weak self] in
                    guard let self else { return (index, nil) }
                    let stock = try? await self.fetchStockUseCase.execute(symbol: symbol)
                    return (index, stock)
                }
            }
            var results: [(Int, Stock)] = []
            for await (index, stock) in group {
                if let stock { results.append((index, stock)) }
            }
            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Free tier: sequential fallback — no delay needed for Finnhub (60 calls/min).
    /// No delay needed — Finnhub allows 60 calls/min.
    /// Sequential kept only as fallback for .freeTier policy.
    private func fetchStocksSequentially(symbols: [String]) async -> [Stock] {
        var results: [Stock] = []
        for symbol in symbols {
            if let stock = try? await fetchStockUseCase.execute(symbol: symbol) {
                results.append(stock)
            }
            if policy.requestDelay > 0 {
                try? await Task.sleep(nanoseconds: policy.requestDelay)
            }
        }
        return results
    }

    private func fetchWatchlistStocks() async -> [Stock] {
        guard let items = try? await fetchWatchlistUseCase.execute() else { return [] }
        return await fetchStocks(symbols: items.map(\.symbol))
    }
}
