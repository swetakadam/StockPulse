//
//  MockStockRepository.swift
//  DomainTests
//

import Foundation
@testable import Domain

final class MockStockRepository: StockRepositoryProtocol {

    var stocksToReturn: [Stock] = [.mockAAPL, .mockGOOGL]
    var searchResultsToReturn: [Stock] = [.mockAAPL]
    var watchlistToReturn: [WatchlistItem] = []
    var shouldThrow = false
    var thrownError: Error = StockDomainError.notFound(symbol: "")

    var fetchStocksCallCount = 0
    var searchCallCount = 0
    var addToWatchlistCallCount = 0
    var removeFromWatchlistCallCount = 0
    var lastAddedSymbol: String?
    var lastRemovedSymbol: String?

    func fetchQuote(symbol: String) async throws -> Quote {
        if shouldThrow { throw thrownError }
        return .mockAAPL
    }

    func fetchStocks(symbols: [String]) async throws -> [Stock] {
        fetchStocksCallCount += 1
        if shouldThrow { throw thrownError }
        return stocksToReturn.filter { symbols.contains($0.symbol) }
    }

    func searchStocks(query: String) async throws -> [Stock] {
        searchCallCount += 1
        if shouldThrow { throw thrownError }
        return searchResultsToReturn
    }

    func fetchWatchlist() async throws -> [WatchlistItem] {
        if shouldThrow { throw thrownError }
        return watchlistToReturn
    }

    func addToWatchlist(symbol: String) async throws {
        addToWatchlistCallCount += 1
        lastAddedSymbol = symbol
        if shouldThrow { throw thrownError }
        let item = WatchlistItem(id: symbol, symbol: symbol, addedAt: Date())
        watchlistToReturn.append(item)
    }

    func removeFromWatchlist(symbol: String) async throws {
        removeFromWatchlistCallCount += 1
        lastRemovedSymbol = symbol
        if shouldThrow { throw thrownError }
        watchlistToReturn.removeAll { $0.symbol == symbol }
    }

    func fetchCompanyOverview(symbol: String) async throws -> CompanyOverview {
        if shouldThrow { throw thrownError }
        return .mockAAPL
    }

    func fetchTimeSeries(symbol: String) async throws -> [PricePoint] {
        if shouldThrow { throw thrownError }
        return []
    }
}
