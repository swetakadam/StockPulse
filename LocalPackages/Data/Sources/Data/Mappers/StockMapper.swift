//
//  StockMapper.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain

enum StockMapper {

    // MARK: - FinnhubQuoteDTO → Stock

    static func toStock(symbol: String, from dto: FinnhubQuoteDTO) -> Stock {
        Stock(
            id: symbol,
            symbol: symbol,
            companyName: symbol,          // populated separately from profile
            currentPrice: dto.current,
            change: dto.change,
            changePercent: dto.changePercent,
            volume: 0,                    // not in /quote endpoint
            marketCap: 0,                 // not in /quote endpoint
            logoURL: nil
        )
    }

    // MARK: - FinnhubQuoteDTO → Quote

    static func toQuote(symbol: String, from dto: FinnhubQuoteDTO) -> Quote {
        Quote(
            symbol: symbol,
            price: dto.current,
            change: dto.change,
            changePercent: dto.changePercent,
            timestamp: Date(),
            volume: 0,                    // not in /quote endpoint
            high: dto.high,
            low: dto.low,
            open: dto.open
        )
    }

    // MARK: - FinnhubProfileDTO → CompanyOverview

    static func toCompanyOverview(symbol: String, from dto: FinnhubProfileDTO) -> CompanyOverview {
        // Finnhub returns marketCapitalization in millions USD — convert to full value
        let marketCap = (dto.marketCapitalization ?? 0) * 1_000_000

        return CompanyOverview(
            symbol: symbol,
            companyName: dto.name ?? symbol,
            description: dto.weburl ?? "No description available.",
            sector: dto.finnhubIndustry ?? "N/A",
            industry: dto.finnhubIndustry ?? "N/A",
            marketCap: marketCap,
            peRatio: nil,         // not available from /stock/profile2
            eps: nil,             // not available from /stock/profile2
            week52High: 0,        // not available from /stock/profile2
            week52Low: 0,         // not available from /stock/profile2
            dividendYield: nil    // not available from /stock/profile2
        )
    }

    // MARK: - FinnhubCandleDTO → [PricePoint]

    static func toPricePoints(from dto: FinnhubCandleDTO) -> [PricePoint] {
        guard dto.status == "ok" else { return [] }
        return zip(dto.timestamps, dto.closes)
            .map { timestamp, close in
                PricePoint(
                    date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    close: close
                )
            }
            .sorted { $0.date < $1.date }
    }

    // MARK: - FinnhubSearchResult → Stock (lightweight, no live price)

    static func toStock(from result: FinnhubSearchResult) -> Stock {
        Stock(
            id: result.symbol,
            symbol: result.symbol,
            companyName: result.description,
            currentPrice: 0,
            change: 0,
            changePercent: 0,
            volume: 0,
            marketCap: 0,
            logoURL: nil
        )
    }
}
