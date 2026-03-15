//
//  FetchRecentSearchesUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public final class FetchRecentSearchesUseCase: FetchRecentSearchesUseCaseProtocol {
    private let repository: RecentSearchRepositoryProtocol

    public init(repository: RecentSearchRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() -> [RecentSearch] {
        return repository.fetchRecentSearches()
    }
}
