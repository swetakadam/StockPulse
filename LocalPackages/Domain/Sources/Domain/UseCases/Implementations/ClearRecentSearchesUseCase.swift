//
//  ClearRecentSearchesUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public final class ClearRecentSearchesUseCase: ClearRecentSearchesUseCaseProtocol {
    private let repository: RecentSearchRepositoryProtocol

    public init(repository: RecentSearchRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() {
        repository.clearAllRecentSearches()
    }

    public func executeOne(query: String) {
        repository.removeRecentSearch(query: query)
    }
}
