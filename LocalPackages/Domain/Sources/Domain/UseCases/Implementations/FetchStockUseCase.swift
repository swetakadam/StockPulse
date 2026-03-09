//
//  FetchStockUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

public final class FetchStockUseCase: FetchStockUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(symbol: String) async throws -> Stock {
        let stocks = try await repository.fetchStocks(symbols: [symbol])
        guard let stock = stocks.first else {
            throw StockDomainError.notFound(symbol: symbol)
        }
        return stock
    }
}
