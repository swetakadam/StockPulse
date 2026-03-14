//
//  StockDetailViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import Combine
import OSLog

// MARK: - Protocol

public protocol StockDetailViewModelProtocol: ObservableObject {
    var symbol:        String           { get }
    var stock:         Stock?           { get }
    var overview:      CompanyOverview? { get }
    var pricePoints:   [PricePoint]     { get }
    var selectedRange: TimeRange        { get set }
    var isLoading:     Bool             { get }
    var error:         String?          { get }
    var isInWatchlist: Bool             { get }
    @MainActor func loadDetail()                    async
    @MainActor func toggleWatchlist()               async
    @MainActor func selectRange(_ range: TimeRange) async
}

// MARK: - ViewModel

public final class StockDetailViewModel: ObservableObject, StockDetailViewModelProtocol {

    public let symbol: String

    private let fetchStockUseCase:           any FetchStockUseCaseProtocol
    private let fetchCompanyOverviewUseCase: any FetchCompanyOverviewUseCaseProtocol
    private let fetchTimeSeriesUseCase:      any FetchTimeSeriesUseCaseProtocol
    private let fetchWatchlistUseCase:       any FetchWatchlistUseCaseProtocol
    private let addToWatchlistUseCase:       any AddToWatchlistUseCaseProtocol
    private let removeFromWatchlistUseCase:  any RemoveFromWatchlistUseCaseProtocol
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "StockDetail")

    @Published public private(set) var stock:         Stock?
    @Published public private(set) var overview:      CompanyOverview?
    @Published public private(set) var pricePoints:   [PricePoint]     = []
    @Published public              var selectedRange: TimeRange        = .oneMonth
    @Published public private(set) var isLoading:     Bool             = false
    @Published public private(set) var error:         String?
    @Published public private(set) var isInWatchlist: Bool             = false

    public init(
        symbol:                      String,
        fetchStockUseCase:           any FetchStockUseCaseProtocol,
        fetchCompanyOverviewUseCase: any FetchCompanyOverviewUseCaseProtocol,
        fetchTimeSeriesUseCase:      any FetchTimeSeriesUseCaseProtocol,
        fetchWatchlistUseCase:       any FetchWatchlistUseCaseProtocol,
        addToWatchlistUseCase:       any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase:  any RemoveFromWatchlistUseCaseProtocol
    ) {
        self.symbol                      = symbol
        self.fetchStockUseCase           = fetchStockUseCase
        self.fetchCompanyOverviewUseCase = fetchCompanyOverviewUseCase
        self.fetchTimeSeriesUseCase      = fetchTimeSeriesUseCase
        self.fetchWatchlistUseCase       = fetchWatchlistUseCase
        self.addToWatchlistUseCase       = addToWatchlistUseCase
        self.removeFromWatchlistUseCase  = removeFromWatchlistUseCase
    }

    // MARK: - Public

    @MainActor
    public func loadDetail() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        async let stockFetch     = loadStock()
        async let overviewFetch  = loadOverview()
        async let seriesFetch    = loadTimeSeries()
        async let watchlistCheck = checkWatchlist()

        let s = await stockFetch
        let o = await overviewFetch
        let p = await seriesFetch
        let w = await watchlistCheck

        stock         = s
        overview      = o
        pricePoints   = p
        isInWatchlist = w

        let stockSymbol  = symbol
        let pointCount   = p.count
        logger.debug("📈 Loaded: \(stockSymbol) — stock=\(s != nil), overview=\(o != nil), points=\(pointCount)")

        if stock == nil {
            error = "Unable to load \(symbol). Please check your connection."
        }
        isLoading = false
    }

    @MainActor
    public func toggleWatchlist() async {
        do {
            if isInWatchlist {
                try await removeFromWatchlistUseCase.execute(symbol: symbol)
                isInWatchlist = false
                let s = symbol
                logger.debug("⭐ Removed from watchlist: \(s)")
            } else {
                try await addToWatchlistUseCase.execute(symbol: symbol)
                isInWatchlist = true
                let s = symbol
                logger.debug("⭐ Added to watchlist: \(s)")
            }
        } catch {
            logger.error("❌ Watchlist toggle failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    public func selectRange(_ range: TimeRange) async {
        selectedRange = range
        pricePoints = await loadTimeSeries(range: range)
        let count = pricePoints.count
        logger.debug("📈 Range changed to \(range.rawValue): \(count) points")
    }

    // MARK: - Private helpers

    private func loadStock() async -> Stock? {
        try? await fetchStockUseCase.execute(symbol: symbol)
    }

    private func loadOverview() async -> CompanyOverview? {
        try? await fetchCompanyOverviewUseCase.execute(symbol: symbol)
    }

    private func loadTimeSeries() async -> [PricePoint] {
        await loadTimeSeries(range: selectedRange)
    }

    private func loadTimeSeries(range: TimeRange) async -> [PricePoint] {
        (try? await fetchTimeSeriesUseCase.execute(symbol: symbol, range: range)) ?? []
    }

    private func checkWatchlist() async -> Bool {
        let items = (try? await fetchWatchlistUseCase.execute()) ?? []
        return items.contains { $0.symbol == symbol }
    }
}
