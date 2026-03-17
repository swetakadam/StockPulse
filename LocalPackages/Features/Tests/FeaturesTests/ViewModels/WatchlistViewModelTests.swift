//
//  WatchlistViewModelTests.swift
//  FeaturesTests
//

import Testing
import Foundation
import Domain
@testable import Features

@Suite("WatchlistViewModel")
@MainActor
struct WatchlistViewModelTests {

    func makeSUT(
        watchlistItems: [WatchlistItem] = []
    ) -> (WatchlistViewModel, MockFetchWatchlistUseCase, MockFetchStockUseCase, MockRemoveFromWatchlistUseCase) {
        let fetchWatchlist = MockFetchWatchlistUseCase()
        fetchWatchlist.watchlistToReturn = watchlistItems
        let fetchStock    = MockFetchStockUseCase()
        let removeUseCase = MockRemoveFromWatchlistUseCase()
        let cache         = MockStockCache()

        let vm = WatchlistViewModel(
            fetchWatchlistUseCase:      fetchWatchlist,
            removeFromWatchlistUseCase: removeUseCase,
            fetchStockUseCase:          fetchStock,
            cache:                      cache
        )
        return (vm, fetchWatchlist, fetchStock, removeUseCase)
    }

    @Test("Initial state is empty and not loading")
    func initialState() {
        let (vm, _, _, _) = makeSUT()

        #expect(vm.stocks.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.error == nil)
    }

    @Test("loadWatchlist populates stocks")
    func loadWatchlistPopulatesStocks() async {
        let item = WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        let (vm, _, _, _) = makeSUT(watchlistItems: [item])

        await vm.loadWatchlist()

        #expect(!vm.stocks.isEmpty)
        #expect(vm.stocks.contains { $0.symbol == "AAPL" })
    }

    @Test("totalValue sums current prices")
    func totalValueSumsCurrentPrices() async {
        let item = WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        let (vm, _, _, _) = makeSUT(watchlistItems: [item])

        await vm.loadWatchlist()

        #expect(vm.totalValue == Stock.mockAAPL.currentPrice)
    }

    @Test("sortedStocks sorts alphabetically by symbol")
    func sortedStocksByName() async {
        let items = [
            WatchlistItem(id: "MSFT", symbol: "MSFT", addedAt: Date()),
            WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        ]
        let (vm, _, _, _) = makeSUT(watchlistItems: items)

        await vm.loadWatchlist()
        vm.sortOption = .name

        #expect(vm.sortedStocks.first?.symbol == "AAPL")
        #expect(vm.sortedStocks.last?.symbol == "MSFT")
    }

    @Test("removeFromWatchlist removes stock from list")
    func removeFromWatchlistRemovesStock() async {
        let item = WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())
        let (vm, _, _, _) = makeSUT(watchlistItems: [item])

        await vm.loadWatchlist()
        await vm.removeFromWatchlist(symbol: "AAPL")

        #expect(!vm.stocks.contains { $0.symbol == "AAPL" })
    }
}
