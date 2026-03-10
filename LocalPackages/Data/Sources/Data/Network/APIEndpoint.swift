//
//  APIEndpoint.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Represents a single Alpha Vantage API endpoint.
/// The apiKey is NOT included here — it is appended by AlphaVantageClient.
public enum APIEndpoint {
    case globalQuote(symbol: String)
    case searchSymbol(query: String)
    case timeSeries(symbol: String, interval: String)
    case overview(symbol: String)

    /// The Alpha Vantage `function` query parameter value.
    public var function: String {
        switch self {
        case .globalQuote:  return "GLOBAL_QUOTE"
        case .searchSymbol: return "SYMBOL_SEARCH"
        case .timeSeries:   return "TIME_SERIES_INTRADAY"
        case .overview:     return "OVERVIEW"
        }
    }

    /// All query items for this endpoint excluding `apikey`.
    public var queryItems: [URLQueryItem] {
        switch self {
        case .globalQuote(let symbol):
            return [
                URLQueryItem(name: "function", value: function),
                URLQueryItem(name: "symbol",   value: symbol)
            ]
        case .searchSymbol(let query):
            return [
                URLQueryItem(name: "function", value: function),
                URLQueryItem(name: "keywords", value: query)
            ]
        case .timeSeries(let symbol, let interval):
            return [
                URLQueryItem(name: "function", value: function),
                URLQueryItem(name: "symbol",   value: symbol),
                URLQueryItem(name: "interval", value: interval)
            ]
        case .overview(let symbol):
            return [
                URLQueryItem(name: "function", value: function),
                URLQueryItem(name: "symbol",   value: symbol)
            ]
        }
    }
}
