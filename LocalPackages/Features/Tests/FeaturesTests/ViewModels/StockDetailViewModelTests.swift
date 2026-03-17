//
//  StockDetailViewModelTests.swift
//  FeaturesTests
//

import Testing
import Foundation
import Domain
@testable import Features

@Suite("StockDetailViewModel")
@MainActor
struct StockDetailViewModelTests {

    func makeSUT(
        watchlistItems: [WatchlistItem] = [],
        stockThrows: Bool = false
    ) -> (StockDetailViewModel, MockFetchStockUseCase, MockAddToWatchlistUseCase, MockRemoveFromWatchlistUseCase) {
        let fetchStock     = MockFetchStockUseCase()
        fetchStock.shouldThrow = stockThrows
        let overview       = MockFetchCompanyOverviewUseCase()
        let timeSeries     = MockFetchTimeSeriesUseCase()
        let addUseCase     = MockAddToWatchlistUseCase()
        let removeUseCase  = MockRemoveFromWatchlistUseCase()
        let fetchWatchlist = MockFetchWatchlistUseCase()
        fetchWatchlist.watchlistToReturn = watchlistItems
        let cache          = MockStockCache()

        let vm = StockDetailViewModel(
            fetchStockUseCase:           fetchStock,
            fetchCompanyOverviewUseCase: overview,
            fetchTimeSeriesUseCase:      timeSeries,
            addToWatchlistUseCase:       addUseCase,
            removeFromWatchlistUseCase:  removeUseCase,
            fetchWatchlistUseCase:       fetchWatchlist,
            cache:                       cache
        )
        return (vm, fetchStock, addUseCase, removeUseCase)
    }

    @Test("Initial state has empty symbol and no stock")
    func initialState() {
        let (vm, _, _, _) = makeSUT()

        #expect(vm.symbol == "")
        #expect(vm.stock == nil)
        #expect(!vm.isLoading)
        #expect(!vm.isInWatchlist)
    }

    @Test("loadDetail sets stock data")
    func loadDetailSetsStock() async {
        let (vm, _, _, _) = makeSUT()

        await vm.loadDetail(symbol: "AAPL")

        #expect(vm.symbol == "AAPL")
        #expect(vm.stock?.symbol == "AAPL")
        #expect(!vm.isLoading)
    }

    @Test("loadDetail sets isInWatchlist when stock is in watchlist")
    func loadDetailSetsIsInWatchlist() async {
        let item = WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        let (vm, _, _, _) = makeSUT(watchlistItems: [item])

        await vm.loadDetail(symbol: "AAPL")

        #expect(vm.isInWatchlist)
    }

    @Test("toggleWatchlist adds stock to watchlist")
    func toggleWatchlistAdds() async {
        let (vm, _, addUseCase, _) = makeSUT()

        await vm.loadDetail(symbol: "AAPL")
        await vm.toggleWatchlist()

        #expect(vm.isInWatchlist)
        #expect(addUseCase.executeCallCount == 1)
    }

    @Test("toggleWatchlist removes stock from watchlist")
    func toggleWatchlistRemoves() async {
        let item = WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        let (vm, _, _, removeUseCase) = makeSUT(watchlistItems: [item])

        await vm.loadDetail(symbol: "AAPL")
        await vm.toggleWatchlist()

        #expect(!vm.isInWatchlist)
        #expect(removeUseCase.executeCallCount == 1)
    }

    @Test("loadDetail sets error when stock fetch fails")
    func loadDetailSetsErrorOnFailure() async {
        let (vm, _, _, _) = makeSUT(stockThrows: true)

        await vm.loadDetail(symbol: "AAPL")

        #expect(vm.stock == nil)
        #expect(vm.error != nil)
    }
}
