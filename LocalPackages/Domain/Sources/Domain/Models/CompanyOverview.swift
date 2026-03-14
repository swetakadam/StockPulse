//
//  CompanyOverview.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - PricePoint

public struct PricePoint: Identifiable {
    public let id: UUID
    public let date: Date
    public let close: Double

    public init(date: Date, close: Double) {
        self.id = UUID()
        self.date = date
        self.close = close
    }
}

// MARK: - TimeRange

public enum TimeRange: String, CaseIterable, Identifiable {
    case oneWeek     = "1W"
    case oneMonth    = "1M"
    case threeMonths = "3M"
    case oneYear     = "1Y"

    public var id: String { rawValue }
}

// MARK: - CompanyOverview

public struct CompanyOverview: Codable, Identifiable, Equatable {
    public var id: String { symbol }
    public let symbol: String
    public let companyName: String
    public let description: String
    public let sector: String
    public let industry: String
    public let marketCap: String
    public let peRatio: String
    public let weekHigh52: String
    public let weekLow52: String
    public let eps: String
    public let avgVolume: String
    public let logoURL: String?

    public init(
        symbol: String,
        companyName: String,
        description: String,
        sector: String,
        industry: String,
        marketCap: String,
        peRatio: String,
        weekHigh52: String,
        weekLow52: String,
        eps: String,
        avgVolume: String,
        logoURL: String?
    ) {
        self.symbol      = symbol
        self.companyName = companyName
        self.description = description
        self.sector      = sector
        self.industry    = industry
        self.marketCap   = marketCap
        self.peRatio     = peRatio
        self.weekHigh52  = weekHigh52
        self.weekLow52   = weekLow52
        self.eps         = eps
        self.avgVolume   = avgVolume
        self.logoURL     = logoURL
    }
}

// MARK: - Mock Data

public extension CompanyOverview {
    static let mockAAPL = CompanyOverview(
        symbol: "AAPL",
        companyName: "Apple Inc.",
        description: "Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide. The Company offers iPhone, a line of smartphones; Mac, a line of personal computers; iPad, a line of multi-purpose tablets; and wearables, home, and accessories.",
        sector: "Technology",
        industry: "Consumer Electronics",
        marketCap: "$2.8T",
        peRatio: "28.5",
        weekHigh52: "$199.62",
        weekLow52: "$164.08",
        eps: "$6.43",
        avgVolume: "58.2M",
        logoURL: "https://static2.finnhub.io/file/publicdatany/finnhubimage/stock_logo/AAPL.png"
    )
}

public extension PricePoint {
    /// 30 days of mock price data in chronological order.
    static let mockList: [PricePoint] = stride(from: 29, through: 0, by: -1).map { i in
        PricePoint(
            date: Date(timeIntervalSinceNow: TimeInterval(-i * 86400)),
            close: 189.84 + Double(i % 7) * 1.5 - 5.0
        )
    }
}
