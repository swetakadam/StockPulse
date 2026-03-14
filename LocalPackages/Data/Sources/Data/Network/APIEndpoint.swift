//
//  APIEndpoint.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Represents a single Finnhub API endpoint.
/// The token is NOT included here — it is appended by FinnhubClient.
public enum APIEndpoint {
    case quote(symbol: String)
    case profile(symbol: String)
    case candles(symbol: String, from: Int, to: Int)
    case search(query: String)
    case overview(symbol: String)    // maps to /stock/profile2 (same as profile)
    case timeSeries(symbol: String)  // daily candles for last 365 days

    /// URL path appended to the base URL for each endpoint.
    public var path: String {
        switch self {
        case .quote:                 return "/quote"
        case .profile, .overview:   return "/stock/profile2"
        case .candles, .timeSeries: return "/stock/candle"
        case .search:               return "/search"
        }
    }

    /// Query items excluding `token` — appended by FinnhubClient.
    public var queryItems: [URLQueryItem] {
        switch self {
        case .quote(let symbol):
            return [
                URLQueryItem(name: "symbol", value: symbol)
            ]

        case .profile(let symbol):
            return [
                URLQueryItem(name: "symbol", value: symbol)
            ]

        case .candles(let symbol, let from, let to):
            return [
                URLQueryItem(name: "symbol",     value: symbol),
                URLQueryItem(name: "resolution", value: "D"),
                URLQueryItem(name: "from",       value: "\(from)"),
                URLQueryItem(name: "to",         value: "\(to)")
            ]

        case .search(let query):
            return [
                URLQueryItem(name: "q", value: query)
            ]

        case .overview(let symbol):
            return [
                URLQueryItem(name: "symbol", value: symbol)
            ]

        case .timeSeries(let symbol):
            // Daily candles for last 365 days
            let to   = Int(Date().timeIntervalSince1970)
            let from = to - (365 * 24 * 60 * 60)
            return [
                URLQueryItem(name: "symbol",     value: symbol),
                URLQueryItem(name: "resolution", value: "D"),
                URLQueryItem(name: "from",       value: "\(from)"),
                URLQueryItem(name: "to",         value: "\(to)")
            ]
        }
    }
}
