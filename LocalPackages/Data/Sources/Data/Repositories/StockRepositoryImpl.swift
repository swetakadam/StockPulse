//
//  StockRepositoryImpl.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain

public final class StockRepositoryImpl: StockRepositoryProtocol {
    private let apiClient: APIClientProtocol
    private let watchlistStore: WatchlistStoreProtocol

    public init(apiClient: APIClientProtocol, watchlistStore: WatchlistStoreProtocol) {
        self.apiClient = apiClient
        self.watchlistStore = watchlistStore
    }

    // MARK: - Quote

    public func fetchQuote(symbol: String) async throws -> Quote {
        let response: GlobalQuoteResponse = try await apiClient.fetch(
            endpoint: .globalQuote(symbol: symbol)
        )
        guard let quote = StockMapper.toQuote(from: response.globalQuote) else {
            throw NetworkError.emptyResponse
        }
        return quote
    }

    // MARK: - Stocks (concurrent batch)

    public func fetchStocks(symbols: [String]) async throws -> [Stock] {
        var stocks: [Stock] = []

        try await withThrowingTaskGroup(of: Stock?.self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let response: GlobalQuoteResponse = try await self.apiClient.fetch(
                            endpoint: .globalQuote(symbol: symbol)
                        )
                        return StockMapper.toStock(from: response.globalQuote)
                    } catch {
                        return nil      // skip individual failures
                    }
                }
            }
            for try await result in group {
                if let stock = result { stocks.append(stock) }
            }
        }

        guard !stocks.isEmpty else { throw NetworkError.emptyResponse }
        return stocks
    }

    // MARK: - Search

    public func searchStocks(query: String) async throws -> [Stock] {
        let response: SymbolSearchResponse = try await apiClient.fetch(
            endpoint: .searchSymbol(query: query)
        )
        return response.bestMatches.map { StockMapper.toStock(from: $0) }
    }

    // MARK: - Watchlist

    public func fetchWatchlist() async throws -> [WatchlistItem] {
        watchlistStore.load().map {
            WatchlistItem(id: $0, symbol: $0, addedAt: Date())
        }
    }

    public func addToWatchlist(symbol: String) async throws {
        watchlistStore.add(symbol: symbol)
    }

    public func removeFromWatchlist(symbol: String) async throws {
        watchlistStore.remove(symbol: symbol)
    }
}
