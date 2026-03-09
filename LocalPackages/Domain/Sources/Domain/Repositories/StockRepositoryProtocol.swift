//
//  StockRepositoryProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

public protocol StockRepositoryProtocol {
    /// Fetch a real-time quote for a single symbol.
    func fetchQuote(symbol: String) async throws -> Quote

    /// Fetch full stock details for one or more symbols.
    func fetchStocks(symbols: [String]) async throws -> [Stock]

    /// Search for stocks matching a query string.
    func searchStocks(query: String) async throws -> [Stock]

    /// Return the user's persisted watchlist.
    func fetchWatchlist() async throws -> [WatchlistItem]

    /// Add a symbol to the user's watchlist.
    func addToWatchlist(symbol: String) async throws

    /// Remove a symbol from the user's watchlist.
    func removeFromWatchlist(symbol: String) async throws
}
