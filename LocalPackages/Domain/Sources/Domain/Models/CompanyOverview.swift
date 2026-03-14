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

public struct CompanyOverview: Equatable {
    public let symbol: String
    public let companyName: String
    public let description: String
    public let sector: String
    public let industry: String
    public let marketCap: Double
    public let peRatio: Double?
    public let eps: Double?
    public let week52High: Double
    public let week52Low: Double
    public let dividendYield: Double?

    public init(
        symbol: String,
        companyName: String,
        description: String,
        sector: String,
        industry: String,
        marketCap: Double,
        peRatio: Double?,
        eps: Double?,
        week52High: Double,
        week52Low: Double,
        dividendYield: Double?
    ) {
        self.symbol        = symbol
        self.companyName   = companyName
        self.description   = description
        self.sector        = sector
        self.industry      = industry
        self.marketCap     = marketCap
        self.peRatio       = peRatio
        self.eps           = eps
        self.week52High    = week52High
        self.week52Low     = week52Low
        self.dividendYield = dividendYield
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
        marketCap: 2_940_000_000_000,
        peRatio: 28.5,
        eps: 6.57,
        week52High: 199.62,
        week52Low: 164.08,
        dividendYield: 0.0051
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
