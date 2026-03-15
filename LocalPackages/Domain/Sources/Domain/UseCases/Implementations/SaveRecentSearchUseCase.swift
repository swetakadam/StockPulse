//
//  SaveRecentSearchUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public final class SaveRecentSearchUseCase: SaveRecentSearchUseCaseProtocol {
    private let repository: RecentSearchRepositoryProtocol

    public init(repository: RecentSearchRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Repository handles dedup and max limit
        repository.saveRecentSearch(query: trimmed)
    }
}
