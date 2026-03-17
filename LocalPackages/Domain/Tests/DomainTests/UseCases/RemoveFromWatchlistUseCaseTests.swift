//
//  RemoveFromWatchlistUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

@Suite("RemoveFromWatchlistUseCase")
struct RemoveFromWatchlistUseCaseTests {

    @Test("Removes existing symbol from watchlist")
    func removesExistingSymbol() async throws {
        let repo = MockStockRepository()
        repo.watchlistToReturn = [WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())]
        let sut = RemoveFromWatchlistUseCase(repository: repo)

        try await sut.execute(symbol: "AAPL")

        #expect(repo.removeFromWatchlistCallCount == 1)
        #expect(repo.lastRemovedSymbol == "AAPL")
        #expect(!repo.watchlistToReturn.contains { $0.symbol == "AAPL" })
    }

    @Test("Idempotent — removing non-existent symbol does not throw")
    func idempotentRemoval() async throws {
        let repo = MockStockRepository()
        repo.watchlistToReturn = []
        let sut = RemoveFromWatchlistUseCase(repository: repo)

        // Should NOT throw and should NOT call repo.removeFromWatchlist
        try await sut.execute(symbol: "AAPL")

        #expect(repo.removeFromWatchlistCallCount == 0)
    }

    @Test("Throws invalidSymbol for empty symbol")
    func throwsInvalidSymbolForEmptySymbol() async throws {
        let repo = MockStockRepository()
        let sut = RemoveFromWatchlistUseCase(repository: repo)

        await #expect(throws: StockDomainError.invalidSymbol) {
            try await sut.execute(symbol: "")
        }
    }
}
