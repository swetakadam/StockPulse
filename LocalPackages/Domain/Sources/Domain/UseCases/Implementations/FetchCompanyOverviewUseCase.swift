//
//  FetchCompanyOverviewUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

public final class FetchCompanyOverviewUseCase: FetchCompanyOverviewUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(symbol: String) async throws -> CompanyOverview {
        try await repository.fetchCompanyOverview(symbol: symbol)
    }
}
