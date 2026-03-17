//
//  FetchWatchlistUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

@Suite("FetchWatchlistUseCase")
struct FetchWatchlistUseCaseTests {

    @Test("Returns watchlist sorted by addedAt descending")
    func returnsSortedByAddedAtDescending() async throws {
        let repo = MockStockRepository()
        let older = WatchlistItem(id: "MSFT", symbol: "MSFT",
                                  addedAt: Date().addingTimeInterval(-3600))
        let newer = WatchlistItem(id: "AAPL", symbol: "AAPL",
                                  addedAt: Date())
        repo.watchlistToReturn = [older, newer]
        let sut = FetchWatchlistUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(result.first?.symbol == "AAPL")
        #expect(result.last?.symbol == "MSFT")
    }

    @Test("Returns empty array for empty watchlist")
    func returnsEmptyArrayForEmptyWatchlist() async throws {
        let repo = MockStockRepository()
        repo.watchlistToReturn = []
        let sut = FetchWatchlistUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(result.isEmpty)
    }
}
