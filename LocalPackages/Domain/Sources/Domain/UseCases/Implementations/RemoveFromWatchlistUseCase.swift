//
//  RemoveFromWatchlistUseCase.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports
// Trimming uses Character.isWhitespace (Swift stdlib, not Foundation)

public final class RemoveFromWatchlistUseCase: RemoveFromWatchlistUseCaseProtocol {
    private let repository: StockRepositoryProtocol

    public init(repository: StockRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(symbol: String) async throws {
        // 1. Trim and validate
        let trimmed = symbol.trimmed
        guard !trimmed.isEmpty else {
            throw StockDomainError.invalidSymbol
        }

        // 2. Silently return if not in watchlist (idempotent remove)
        let current = try await repository.fetchWatchlist()
        guard current.contains(where: { $0.symbol == trimmed }) else {
            return
        }

        // 3. Remove
        try await repository.removeFromWatchlist(symbol: trimmed)
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
