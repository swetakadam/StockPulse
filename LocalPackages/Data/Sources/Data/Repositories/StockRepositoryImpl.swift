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
        self.apiClient      = apiClient
        self.watchlistStore = watchlistStore
        self.cache          = cache
    }

    // MARK: - Quote

    public func fetchQuote(symbol: String) async throws -> Quote {
        let dto: FinnhubQuoteDTO = try await apiClient.fetch(endpoint: .quote(symbol: symbol))
        return StockMapper.toQuote(symbol: symbol, from: dto)
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
        let dto: FinnhubQuoteDTO = try await apiClient.fetch(endpoint: .quote(symbol: symbol))
        return StockMapper.toStock(symbol: symbol, from: dto)
    }

    // MARK: - Search

    public func searchStocks(query: String) async throws -> [Stock] {
        let response: FinnhubSearchResponse = try await apiClient.fetch(
            endpoint: .search(query: query)
        )
        return response.result.map { StockMapper.toStock(from: $0) }
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

    // MARK: - Company Overview (profile + metrics, UserDefaults-cached)

    public func fetchCompanyOverview(symbol: String) async throws -> CompanyOverview {
        let cacheKey = "overview_\(symbol)"
        if let cached = UserDefaults.standard.data(forKey: cacheKey),
           let overview = try? JSONDecoder().decode(CompanyOverview.self, from: cached) {
            return overview
        }

        async let profileDTO: FinnhubProfileDTO = apiClient.fetch(
            endpoint: .overview(symbol: symbol)
        )
        async let metricsResponse: FinnhubMetricsResponse = apiClient.fetch(
            endpoint: .metrics(symbol: symbol)
        )

        let (profile, metrics) = try await (profileDTO, metricsResponse)
        let overview = StockMapper.toCompanyOverview(
            symbol: symbol,
            profile: profile,
            metrics: metrics.metric
        )

        if let data = try? JSONEncoder().encode(overview) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
        return overview
    }

    // MARK: - Daily Time Series

    public func fetchTimeSeries(symbol: String) async throws -> [PricePoint] {
        let dto: FinnhubCandleDTO = try await apiClient.fetch(
            endpoint: .timeSeries(symbol: symbol)
        )
        return StockMapper.toPricePoints(from: dto)
    }
}
