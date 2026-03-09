//
//  AddToWatchlistUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports
// Trimming uses Character.isWhitespace (Swift stdlib, not Foundation)

public final class AddToWatchlistUseCase: AddToWatchlistUseCaseProtocol {
    private let repository: StockRepositoryProtocol
    private let maxWatchlistSize = 50

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(symbol: String) async throws {
        // 1. Trim and validate
        let trimmed = symbol.trimmed
        guard !trimmed.isEmpty else {
            throw StockDomainError.invalidSymbol
        }

        let current = try await repository.fetchWatchlist()

        // 2. Silently return if already in watchlist (idempotent add)
        guard !current.contains(where: { $0.symbol == trimmed }) else {
            return
        }

        // 3. Enforce max size
        guard current.count < maxWatchlistSize else {
            throw StockDomainError.watchlistFull
        }

        // 4. Persist
        try await repository.addToWatchlist(symbol: trimmed)
    }
}

// MARK: - Pure Swift trim helper (no Foundation)

private extension String {
    var trimmed: String {
        var result = self[startIndex...]
        while result.first?.isWhitespace == true { result = result.dropFirst() }
        while result.last?.isWhitespace == true  { result = result.dropLast() }
        return String(result)
    }
}
