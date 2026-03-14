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
    private let cache: StockCacheProtocol

    public init(
        apiClient: APIClientProtocol,
        watchlistStore: WatchlistStoreProtocol,
        cache: StockCacheProtocol
    ) {
        self.apiClient = apiClient
        self.watchlistStore = watchlistStore
        self.cache = cache
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

    // MARK: - Stocks (cache-first)

    public func fetchStocks(symbols: [String]) async throws -> [Stock] {
        var results: [(Int, Stock)] = []
        for (index, symbol) in symbols.enumerated() {
            if let cached = cache.stock(for: symbol) {
                results.append((index, cached))
            } else if let stock = try? await fetchStockFromNetwork(symbol: symbol) {
                cache.save(stock)
                results.append((index, stock))
            }
        }
        guard !results.isEmpty else { throw NetworkError.emptyResponse }
        return results.sorted { $0.0 < $1.0 }.map(\.1)
    }

    private func fetchStockFromNetwork(symbol: String) async throws -> Stock {
        let response: GlobalQuoteResponse = try await apiClient.fetch(
            endpoint: .globalQuote(symbol: symbol)
        )
        let stock = StockMapper.toStock(from: response.globalQuote)
        return stock
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
