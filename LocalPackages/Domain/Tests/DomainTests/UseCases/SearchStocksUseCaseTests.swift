//
//  SearchStocksUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

@Suite("SearchStocksUseCase")
struct SearchStocksUseCaseTests {

    @Test("Returns results for valid query")
    func returnsResultsForValidQuery() async throws {
        let repo = MockStockRepository()
        let sut = SearchStocksUseCase(repository: repo)

        let results = try await sut.execute(query: "Apple")

        #expect(!results.isEmpty)
        #expect(repo.searchCallCount == 1)
    }

    @Test("Throws emptyQuery for blank query")
    func throwsEmptyQueryForBlankQuery() async throws {
        let repo = MockStockRepository()
        let sut = SearchStocksUseCase(repository: repo)

        await #expect(throws: StockDomainError.emptyQuery) {
            try await sut.execute(query: "   ")
        }
    }

    @Test("Throws emptyQuery for empty string")
    func throwsEmptyQueryForEmptyString() async throws {
        let repo = MockStockRepository()
        let sut = SearchStocksUseCase(repository: repo)

        await #expect(throws: StockDomainError.emptyQuery) {
            try await sut.execute(query: "")
        }
    }

    @Test("Trims whitespace before searching")
    func trimsWhitespaceBeforeSearching() async throws {
        let repo = MockStockRepository()
        let sut = SearchStocksUseCase(repository: repo)

        let results = try await sut.execute(query: "  Apple  ")

        #expect(!results.isEmpty)
    }
}
