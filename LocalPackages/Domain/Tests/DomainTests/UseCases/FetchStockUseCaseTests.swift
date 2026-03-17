//
//  FetchStockUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

@Suite("FetchStockUseCase")
struct FetchStockUseCaseTests {

    @Test("Returns stock for valid symbol")
    func returnsStockForValidSymbol() async throws {
        let repo = MockStockRepository()
        let sut = FetchStockUseCase(repository: repo)

        let stock = try await sut.execute(symbol: "AAPL")

        #expect(stock.symbol == "AAPL")
        #expect(repo.fetchStocksCallCount == 1)
    }

    @Test("Throws notFound for unknown symbol")
    func throwsNotFoundForUnknownSymbol() async throws {
        let repo = MockStockRepository()
        repo.stocksToReturn = []
        let sut = FetchStockUseCase(repository: repo)

        await #expect(throws: StockDomainError.notFound(symbol: "UNKNOWN")) {
            try await sut.execute(symbol: "UNKNOWN")
        }
    }

    @Test("Propagates repository error")
    func propagatesRepositoryError() async throws {
        let repo = MockStockRepository()
        repo.shouldThrow = true
        let sut = FetchStockUseCase(repository: repo)

        await #expect(throws: (any Error).self) {
            try await sut.execute(symbol: "AAPL")
        }
    }
}
