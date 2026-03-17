//
//  AddToWatchlistUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

@Suite("AddToWatchlistUseCase")
struct AddToWatchlistUseCaseTests {

    @Test("Adds valid symbol to watchlist")
    func addsValidSymbolToWatchlist() async throws {
        let repo = MockStockRepository()
        let sut = AddToWatchlistUseCase(repository: repo)

        try await sut.execute(symbol: "AAPL")

        #expect(repo.addToWatchlistCallCount == 1)
        #expect(repo.lastAddedSymbol == "AAPL")
        #expect(repo.watchlistToReturn.contains { $0.symbol == "AAPL" })
    }

    @Test("Silently ignores duplicate symbol")
    func silentlyIgnoresDuplicate() async throws {
        let repo = MockStockRepository()
        repo.watchlistToReturn = [WatchlistItem(id: "AAPL", symbol: "AAPL", addedAt: Date())]
        let sut = AddToWatchlistUseCase(repository: repo)

        try await sut.execute(symbol: "AAPL")

        // addToWatchlist on repo never called — use case returned early
        #expect(repo.addToWatchlistCallCount == 0)
        #expect(repo.watchlistToReturn.filter { $0.symbol == "AAPL" }.count == 1)
    }

    @Test("Throws invalidSymbol for empty symbol")
    func throwsInvalidSymbolForEmptySymbol() async throws {
        let repo = MockStockRepository()
        let sut = AddToWatchlistUseCase(repository: repo)

        await #expect(throws: StockDomainError.invalidSymbol) {
            try await sut.execute(symbol: "")
        }
    }

    @Test("Throws watchlistFull when at 50 stocks")
    func throwsWatchlistFullAt50Stocks() async throws {
        let repo = MockStockRepository()
        repo.watchlistToReturn = (0..<50).map {
            WatchlistItem(id: "SYM\($0)", symbol: "SYM\($0)", addedAt: Date())
        }
        let sut = AddToWatchlistUseCase(repository: repo)

        await #expect(throws: StockDomainError.watchlistFull) {
            try await sut.execute(symbol: "NEWSTOCK")
        }
    }
}
