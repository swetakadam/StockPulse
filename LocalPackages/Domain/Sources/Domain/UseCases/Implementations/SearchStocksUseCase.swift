//
//  SearchStocksUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation   // required for String.trimmingCharacters(in:)

public final class SearchStocksUseCase: SearchStocksUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Stock] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw StockDomainError.emptyQuery
        }
        return try await repository.searchStocks(query: trimmed)
    }
}
