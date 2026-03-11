//
//  DashboardViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import Combine

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
        fetchWatchlistUseCase: any FetchWatchlistUseCaseProtocol
    ) {
        self.fetchStockUseCase     = fetchStockUseCase
        self.fetchWatchlistUseCase = fetchWatchlistUseCase
    }

    // MARK: - Public

    @MainActor
    public func loadDashboard() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        async let trending  = fetchStocks(symbols: trendingSymbols)
        async let gainers   = fetchStocks(symbols: gainerSymbols)
        async let losers    = fetchStocks(symbols: loserSymbols)
        async let watchlist = fetchWatchlistStocks()

        let (t, g, l, w) = await (trending, gainers, losers, watchlist)
        trendingStocks  = t
        topGainers      = g
        topLosers       = l
        watchlistStocks = w

        if t.isEmpty && g.isEmpty && l.isEmpty {
            error = "Unable to load market data. Please check your connection."
        }
        isLoading = false
    }

    @MainActor
    public func refreshDashboard() async {
        isLoading = false           // reset guard so refresh always fires
        await loadDashboard()
    }

    // MARK: - Private helpers

    private func fetchStocks(symbols: [String]) async -> [Stock] {
        await withTaskGroup(of: Stock?.self) { group in
            for symbol in symbols {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return try? await self.fetchStockUseCase.execute(symbol: symbol)
                }
            }
            var results: [Stock] = []
            for await stock in group {
                if let stock { results.append(stock) }
            }
            return results
        }
    }

    private func fetchWatchlistStocks() async -> [Stock] {
        guard let items = try? await fetchWatchlistUseCase.execute() else { return [] }
        return await fetchStocks(symbols: items.map(\.symbol))
    }
}
