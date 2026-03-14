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
    @MainActor func loadDetail(symbol: String)      async
    @MainActor func toggleWatchlist()               async
    @MainActor func selectRange(_ range: TimeRange) async
}

// MARK: - ViewModel

public final class StockDetailViewModel: ObservableObject, StockDetailViewModelProtocol {

    @Published public private(set) var symbol: String = ""

    private let fetchStockUseCase:           any FetchStockUseCaseProtocol
    private let fetchCompanyOverviewUseCase: any FetchCompanyOverviewUseCaseProtocol
    private let fetchTimeSeriesUseCase:      any FetchTimeSeriesUseCaseProtocol
    private let addToWatchlistUseCase:       any AddToWatchlistUseCaseProtocol
    private let removeFromWatchlistUseCase:  any RemoveFromWatchlistUseCaseProtocol
    private let cache:                       any StockCacheProtocol
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "StockDetail")

    @Published public private(set) var stock:         Stock?
    @Published public private(set) var overview:      CompanyOverview?
    @Published public private(set) var pricePoints:   [PricePoint]     = []
    @Published public              var selectedRange: TimeRange        = .oneMonth
    @Published public private(set) var isLoading:     Bool             = false
    @Published public private(set) var error:         String?
    @Published public private(set) var isInWatchlist: Bool             = false

    public init(
        fetchStockUseCase:           any FetchStockUseCaseProtocol,
        fetchCompanyOverviewUseCase: any FetchCompanyOverviewUseCaseProtocol,
        fetchTimeSeriesUseCase:      any FetchTimeSeriesUseCaseProtocol,
        addToWatchlistUseCase:       any AddToWatchlistUseCaseProtocol,
        removeFromWatchlistUseCase:  any RemoveFromWatchlistUseCaseProtocol,
        cache:                       any StockCacheProtocol
    ) {
        self.fetchStockUseCase           = fetchStockUseCase
        self.fetchCompanyOverviewUseCase = fetchCompanyOverviewUseCase
        self.fetchTimeSeriesUseCase      = fetchTimeSeriesUseCase
        self.addToWatchlistUseCase       = addToWatchlistUseCase
        self.removeFromWatchlistUseCase  = removeFromWatchlistUseCase
        self.cache                       = cache
    }

    // MARK: - Public

    @MainActor
    public func loadDetail(symbol: String) async {
        guard !isLoading else { return }
        self.symbol = symbol
        isLoading = true
        error = nil
        isInWatchlist = false

        async let stockFetch    = loadStock()
        async let overviewFetch = loadOverview()
        async let seriesFetch   = loadTimeSeries()

        let s = await stockFetch
        let o = await overviewFetch
        let p = await seriesFetch

        stock       = s
        overview    = o
        pricePoints = p

        let pointCount = p.count
        logger.debug("📈 Loaded: \(symbol) — stock=\(s != nil), overview=\(o != nil), points=\(pointCount)")

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

}
