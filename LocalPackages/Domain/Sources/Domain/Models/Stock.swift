//
//  Stock.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Stock

public struct Stock: Identifiable, Codable, Equatable {
    public let id: String           // same as symbol
    public let symbol: String
    public let companyName: String
    public let currentPrice: Double
    public let change: Double
    public let changePercent: Double
    public let volume: Int
    public let marketCap: Double
    public let logoURL: URL?

    public init(
        id: String,
        symbol: String,
        companyName: String,
        currentPrice: Double,
        change: Double,
        changePercent: Double,
        volume: Int,
        marketCap: Double,
        logoURL: URL? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.companyName = companyName
        self.currentPrice = currentPrice
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.marketCap = marketCap
        self.logoURL = logoURL
    }
}

// MARK: - Quote

public struct Quote: Identifiable, Codable, Equatable {
    public var id: String { symbol }
    public let symbol: String
    public let price: Double
    public let change: Double
    public let changePercent: Double
    public let timestamp: Date
    public let volume: Int
    public let high: Double
    public let low: Double
    public let open: Double

    public init(
        symbol: String,
        price: Double,
        change: Double,
        changePercent: Double,
        timestamp: Date,
        volume: Int,
        high: Double,
        low: Double,
        open: Double
    ) {
        self.symbol = symbol
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.timestamp = timestamp
        self.volume = volume
        self.high = high
        self.low = low
        self.open = open
    }
}

// MARK: - WatchlistItem

public struct WatchlistItem: Identifiable, Codable, Equatable {
    public let id: String           // same as symbol
    public let symbol: String
    public let addedAt: Date

    public init(id: String, symbol: String, addedAt: Date) {
        self.id = id
        self.symbol = symbol
        self.addedAt = addedAt
    }
}

// MARK: - Domain Errors

public enum StockDomainError: Error, LocalizedError, Equatable {
    case notFound(symbol: String)
    case emptyQuery
    case watchlistFull
    case invalidSymbol

    public var errorDescription: String? {
        switch self {
        case .notFound(let symbol): return "Stock '\(symbol)' could not be found."
        case .emptyQuery:           return "Search query must not be empty."
        case .watchlistFull:        return "Watchlist has reached its maximum size of 50 items."
        case .invalidSymbol:        return "The provided symbol is invalid."
        }
    }
}

// MARK: - Mock Data (previews / tests only)

public extension Stock {
    static let mockAAPL = Stock(
        id: "AAPL", symbol: "AAPL", companyName: "Apple Inc.",
        currentPrice: 189.84, change: 2.34, changePercent: 1.25,
        volume: 54_823_400, marketCap: 2_940_000_000_000
    )
    static let mockGOOGL = Stock(
        id: "GOOGL", symbol: "GOOGL", companyName: "Alphabet Inc.",
        currentPrice: 175.12, change: -1.08, changePercent: -0.61,
        volume: 21_340_200, marketCap: 2_190_000_000_000
    )
    static let mockMSFT = Stock(
        id: "MSFT", symbol: "MSFT", companyName: "Microsoft Corporation",
        currentPrice: 415.50, change: 5.20, changePercent: 1.27,
        volume: 18_920_100, marketCap: 3_090_000_000_000
    )
    static let mockAMZN = Stock(
        id: "AMZN", symbol: "AMZN", companyName: "Amazon.com Inc.",
        currentPrice: 228.30, change: -0.90, changePercent: -0.39,
        volume: 32_100_500, marketCap: 2_420_000_000_000
    )
    static let mockTSLA = Stock(
        id: "TSLA", symbol: "TSLA", companyName: "Tesla Inc.",
        currentPrice: 178.20, change: 4.60, changePercent: 2.65,
        volume: 89_401_700, marketCap: 568_000_000_000
    )
    static let mockList: [Stock] = [mockAAPL, mockGOOGL, mockMSFT, mockAMZN, mockTSLA]
}

public extension Quote {
    static let mockAAPL = Quote(
        symbol: "AAPL", price: 189.84, change: 2.34, changePercent: 1.25,
        timestamp: Date(), volume: 54_823_400,
        high: 191.10, low: 187.20, open: 187.50
    )
    static let mockGOOGL = Quote(
        symbol: "GOOGL", price: 175.12, change: -1.08, changePercent: -0.61,
        timestamp: Date(), volume: 21_340_200,
        high: 176.50, low: 173.80, open: 174.20
    )
    static let mockMSFT = Quote(
        symbol: "MSFT", price: 415.50, change: 5.20, changePercent: 1.27,
        timestamp: Date(), volume: 18_920_100,
        high: 417.00, low: 410.30, open: 411.00
    )
}

public extension WatchlistItem {
    static let mockAAPL = WatchlistItem(
        id: "AAPL", symbol: "AAPL",
        addedAt: Date(timeIntervalSinceNow: -86400)
    )
    static let mockMSFT = WatchlistItem(
        id: "MSFT", symbol: "MSFT",
        addedAt: Date(timeIntervalSinceNow: -3600)
    )
    static let mockTSLA = WatchlistItem(
        id: "TSLA", symbol: "TSLA",
        addedAt: Date()
    )
    static let mockList: [WatchlistItem] = [mockAAPL, mockMSFT, mockTSLA]
}
