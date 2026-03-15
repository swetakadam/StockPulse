//
//  WatchlistViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import OSLog

// MARK: - Sort Option

public enum WatchlistSortOption: String, CaseIterable {
    case name          = "Name"
    case price         = "Price"
    case changePercent = "Change %"
}

// MARK: - Protocol

public protocol WatchlistViewModelProtocol: ObservableObject {
    var stocks:       [Stock]              { get }
    var sortedStocks: [Stock]              { get }
    var sortOption:   WatchlistSortOption  { get set }
    var isLoading:    Bool                 { get }
    var error:        String?              { get }
    var totalValue:   Double               { get }
    @MainActor func loadWatchlist()                     async
    @MainActor func refreshWatchlist()                  async
    @MainActor func removeFromWatchlist(symbol: String) async
}

// MARK: - ViewModel

public final class WatchlistViewModel: ObservableObject, WatchlistViewModelProtocol {

    private let fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol
    private let removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol
    private let fetchStockUseCase:          any FetchStockUseCaseProtocol
    private let cache:                      any StockCacheProtocol
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Watchlist")

    @Published public private(set) var stocks:    [Stock] = []
    @Published public var sortOption: WatchlistSortOption = .name
    @Published public private(set) var isLoading: Bool    = false
    @Published public private(set) var error:     String?

    public var totalValue: Double {
        stocks.reduce(0) { $0 + $1.currentPrice }
    }

    public var sortedStocks: [Stock] {
        switch sortOption {
        case .name:          return stocks.sorted { $0.symbol < $1.symbol }
        case .price:         return stocks.sorted { $0.currentPrice > $1.currentPrice }
        case .changePercent: return stocks.sorted { $0.changePercent > $1.changePercent }
        }
    }

    public init(
        fetchWatchlistUseCase:      any FetchWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase: any RemoveFromWatchlistUseCaseProtocol,
        fetchStockUseCase:          any FetchStockUseCaseProtocol,
        cache:                      any StockCacheProtocol
    ) {
        self.fetchWatchlistUseCase      = fetchWatchlistUseCase
        self.removeFromWatchlistUseCase = removeFromWatchlistUseCase
        self.fetchStockUseCase          = fetchStockUseCase
        self.cache                      = cache
    }

    // MARK: - Load

    @MainActor
    public func loadWatchlist() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        // Phase 1: serve from cache instantly
        await loadFromCache()

        // Phase 2: fetch fresh data from network
        await fetchLivePrices()

        isLoading = false
    }

    @MainActor
    public func refreshWatchlist() async {
        isLoading = false
        await loadWatchlist()
    }

    @MainActor
    public func removeFromWatchlist(symbol: String) async {
        do {
            try await removeFromWatchlistUseCase.execute(symbol: symbol)
            stocks.removeAll { $0.symbol == symbol }
            logger.debug("🗑 Removed \(symbol) from watchlist")
        } catch {
            self.error = "Failed to remove \(symbol) from watchlist."
            logger.error("🗑 Remove failed for \(symbol): \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    @MainActor
    private func loadFromCache() async {
        guard let items = try? await fetchWatchlistUseCase.execute() else { return }
        let cachedStocks = items.compactMap { cache.stock(for: $0.symbol) }
        if !cachedStocks.isEmpty {
            stocks = cachedStocks
            isLoading = false
            logger.debug("📦 Loaded \(cachedStocks.count) watchlist stocks from cache")
        }
    }

    @MainActor
    private func fetchLivePrices() async {
        guard let items = try? await fetchWatchlistUseCase.execute(),
              !items.isEmpty else {
            stocks = []
            return
        }
        let fetched = await withTaskGroup(of: Stock?.self) { group in
            for item in items {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return try? await self.fetchStockUseCase.execute(symbol: item.symbol)
                }
            }
            var results: [Stock] = []
            for await stock in group {
                if let stock { results.append(stock) }
            }
            return results
        }
        if !fetched.isEmpty {
            stocks = fetched
            logger.debug("📊 Fetched \(fetched.count) watchlist stocks from network")
        }
    }
}
