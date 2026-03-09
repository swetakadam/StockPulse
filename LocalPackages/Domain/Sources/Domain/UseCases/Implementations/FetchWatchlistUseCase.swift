//
//  FetchWatchlistUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation   // required for Date's Comparable (sorting by addedAt)

public final class FetchWatchlistUseCase: FetchWatchlistUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [WatchlistItem] {
        let items = try await repository.fetchWatchlist()
        return items.sorted { $0.addedAt > $1.addedAt }
    }
}
