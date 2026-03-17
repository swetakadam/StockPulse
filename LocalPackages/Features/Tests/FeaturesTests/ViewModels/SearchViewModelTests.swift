//
//  SearchViewModelTests.swift
//  FeaturesTests
//

import Testing
import Foundation
import Domain
@testable import Features

@Suite("SearchViewModel")
@MainActor
struct SearchViewModelTests {

    func makeSUT(
        searchResults: [Stock] = [.mockAAPL],
        shouldThrow: Bool = false,
        recentSearches: [RecentSearch] = []
    ) -> (SearchViewModel, MockSearchStocksUseCase, MockFetchRecentSearchesUseCase, MockAddToWatchlistUseCase) {
        let searchUseCase    = MockSearchStocksUseCase()
        searchUseCase.resultsToReturn = searchResults
        searchUseCase.shouldThrow    = shouldThrow
        let fetchRecent      = MockFetchRecentSearchesUseCase()
        fetchRecent.searchesToReturn = recentSearches
        let addUseCase       = MockAddToWatchlistUseCase()
        let saveRecent       = MockSaveRecentSearchUseCase()
        let clearRecent      = MockClearRecentSearchesUseCase()

        let vm = SearchViewModel(
            searchStocksUseCase:        searchUseCase,
            addToWatchlistUseCase:      addUseCase,
            fetchRecentSearchesUseCase: fetchRecent,
            saveRecentSearchUseCase:    saveRecent,
            clearRecentSearchesUseCase: clearRecent
        )
        return (vm, searchUseCase, fetchRecent, addUseCase)
    }

    @Test("Initial state has empty results and no error")
    func initialState() {
        let (vm, _, _, _) = makeSUT()

        #expect(vm.query == "")
        #expect(vm.results.isEmpty)
        #expect(vm.error == nil)
        #expect(!vm.isLoading)
    }

    @Test("Search returns results for valid query")
    func searchReturnsResults() async {
        let (vm, searchUseCase, _, _) = makeSUT()

        await vm.search(query: "Apple")

        #expect(!vm.results.isEmpty)
        #expect(searchUseCase.executeCallCount == 1)
        #expect(vm.error == nil)
    }

    @Test("Empty query clears results without searching")
    func emptyQueryClearsResults() async {
        let (vm, searchUseCase, _, _) = makeSUT()

        // Pre-load results
        await vm.search(query: "Apple")
        let resultCountAfterSearch = vm.results.count

        await vm.search(query: "")

        #expect(vm.results.isEmpty)
        #expect(searchUseCase.executeCallCount == 1)
        #expect(resultCountAfterSearch > 0)
    }

    @Test("Search failure sets error")
    func searchFailureSetsError() async {
        let (vm, _, _, _) = makeSUT(shouldThrow: true)

        await vm.search(query: "UNKNOWN")

        #expect(vm.error != nil)
        #expect(vm.results.isEmpty)
    }

    @Test("clearRecentSearches empties recent searches")
    func clearRecentSearchesEmptiesRecentSearches() {
        let fetchUseCase = MockFetchRecentSearchesUseCase()
        fetchUseCase.searchesToReturn = [RecentSearch(query: "AAPL")]
        let clearUseCase = MockClearRecentSearchesUseCase()

        let sut = SearchViewModel(
            searchStocksUseCase:        MockSearchStocksUseCase(),
            addToWatchlistUseCase:      MockAddToWatchlistUseCase(),
            fetchRecentSearchesUseCase: fetchUseCase,
            saveRecentSearchUseCase:    MockSaveRecentSearchUseCase(),
            clearRecentSearchesUseCase: clearUseCase
        )

        // After clear, fetch returns empty
        fetchUseCase.searchesToReturn = []
        sut.clearRecentSearches()

        #expect(clearUseCase.executeCallCount == 1)
        #expect(sut.recentSearches.isEmpty)
    }

    @Test("addToWatchlist calls use case with correct symbol")
    func addToWatchlist() async {
        let (vm, _, _, addUseCase) = makeSUT()

        await vm.addToWatchlist(symbol: "AAPL")

        #expect(addUseCase.executeCallCount == 1)
        #expect(addUseCase.lastSymbol == "AAPL")
    }
}
