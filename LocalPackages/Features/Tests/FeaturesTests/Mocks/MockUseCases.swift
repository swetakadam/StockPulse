//
//  MockUseCases.swift
//  FeaturesTests
//

import Foundation
import Domain
@testable import Features

// MARK: - MockFetchStockUseCase

final class MockFetchStockUseCase: FetchStockUseCaseProtocol {
    var stocksBySymbol: [String: Stock] = [
        "AAPL":  .mockAAPL,
        "MSFT":  .mockMSFT,
        "GOOGL": .mockGOOGL
    ]
    var shouldThrow = false
    var executeCallCount = 0

    func execute(symbol: String) async throws -> Stock {
        executeCallCount += 1
        if shouldThrow { throw StockDomainError.notFound(symbol: symbol) }
        guard let stock = stocksBySymbol[symbol] else {
            throw StockDomainError.notFound(symbol: symbol)
        }
        return stock
    }
}

// MARK: - MockSearchStocksUseCase

final class MockSearchStocksUseCase: SearchStocksUseCaseProtocol {
    var resultsToReturn: [Stock] = [.mockAAPL, .mockGOOGL]
    var shouldThrow = false
    var executeCallCount = 0

    func execute(query: String) async throws -> [Stock] {
        executeCallCount += 1
        if shouldThrow { throw StockDomainError.emptyQuery }
        return resultsToReturn
    }
}

// MARK: - MockFetchWatchlistUseCase

final class MockFetchWatchlistUseCase: FetchWatchlistUseCaseProtocol {
    var watchlistToReturn: [WatchlistItem] = []
    var shouldThrow = false

    func execute() async throws -> [WatchlistItem] {
        if shouldThrow { throw StockDomainError.notFound(symbol: "") }
        return watchlistToReturn
    }
}

// MARK: - MockAddToWatchlistUseCase

final class MockAddToWatchlistUseCase: AddToWatchlistUseCaseProtocol {
    var shouldThrow = false
    var executeCallCount = 0
    var lastSymbol: String?

    func execute(symbol: String) async throws {
        executeCallCount += 1
        lastSymbol = symbol
        if shouldThrow { throw StockDomainError.watchlistFull }
    }
}

// MARK: - MockRemoveFromWatchlistUseCase

final class MockRemoveFromWatchlistUseCase: RemoveFromWatchlistUseCaseProtocol {
    var shouldThrow = false
    var executeCallCount = 0
    var lastSymbol: String?

    func execute(symbol: String) async throws {
        executeCallCount += 1
        lastSymbol = symbol
        if shouldThrow { throw StockDomainError.invalidSymbol }
    }
}

// MARK: - MockFetchRecentSearchesUseCase

final class MockFetchRecentSearchesUseCase: FetchRecentSearchesUseCaseProtocol {
    var searchesToReturn: [RecentSearch] = []

    func execute() -> [RecentSearch] { searchesToReturn }
}

// MARK: - MockSaveRecentSearchUseCase

final class MockSaveRecentSearchUseCase: SaveRecentSearchUseCaseProtocol {
    var executeCallCount = 0

    func execute(query: String) {
        executeCallCount += 1
    }
}

// MARK: - MockClearRecentSearchesUseCase

final class MockClearRecentSearchesUseCase: ClearRecentSearchesUseCaseProtocol {
    var executeCallCount = 0
    var executeOneCallCount = 0
    var lastQuery: String?

    func execute() {
        executeCallCount += 1
    }

    func executeOne(query: String) {
        executeOneCallCount += 1
        lastQuery = query
    }
}

// MARK: - MockStockCache

final class MockStockCache: StockCacheProtocol {
    var cachedStocks: [String: Stock] = [:]

    func stock(for symbol: String) -> Stock? { cachedStocks[symbol] }
    func save(_ stock: Stock) { cachedStocks[stock.symbol] = stock }
    func invalidate(symbol: String) { cachedStocks.removeValue(forKey: symbol) }
    func invalidateAll() { cachedStocks.removeAll() }
}

// MARK: - MockFetchCompanyOverviewUseCase

final class MockFetchCompanyOverviewUseCase: FetchCompanyOverviewUseCaseProtocol {
    var overviewToReturn: CompanyOverview = .mockAAPL
    var shouldThrow = false

    func execute(symbol: String) async throws -> CompanyOverview {
        if shouldThrow { throw StockDomainError.notFound(symbol: symbol) }
        return overviewToReturn
    }
}

// MARK: - MockFetchTimeSeriesUseCase

final class MockFetchTimeSeriesUseCase: FetchTimeSeriesUseCaseProtocol {
    var pointsToReturn: [PricePoint] = PricePoint.mockList
    var shouldThrow = false

    func execute(symbol: String, range: TimeRange) async throws -> [PricePoint] {
        if shouldThrow { throw StockDomainError.notFound(symbol: symbol) }
        return pointsToReturn
    }
}
