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

    // MARK: - FinnhubProfileDTO + FinnhubMetricData → CompanyOverview

    static func toCompanyOverview(
        symbol: String,
        profile: FinnhubProfileDTO,
        metrics: FinnhubMetricData
    ) -> CompanyOverview {

        let marketCapStr: String = {
            let value = (metrics.marketCapitalization ?? 0) * 1_000_000
            if value >= 1_000_000_000_000 {
                return String(format: "$%.1fT", value / 1_000_000_000_000)
            } else if value >= 1_000_000_000 {
                return String(format: "$%.1fB", value / 1_000_000_000)
            }
            return "$\(Int(value))"
        }()

        let avgVolumeStr: String = {
            let value = (metrics.avgVolume10Day ?? 0) * 1_000_000
            if value >= 1_000_000 {
                return String(format: "%.1fM", value / 1_000_000)
            } else if value >= 1_000 {
                return String(format: "%.1fK", value / 1_000)
            }
            return String(format: "%.0f", value)
        }()

        return CompanyOverview(
            symbol: symbol,
            companyName: profile.name ?? symbol,
            description: profile.weburl ?? "No description available.",
            sector: profile.finnhubIndustry ?? "N/A",
            industry: profile.finnhubIndustry ?? "N/A",
            marketCap: marketCapStr,
            peRatio: metrics.peRatio.map { String(format: "%.1f", $0) } ?? "N/A",
            weekHigh52: metrics.weekHigh52.map { String(format: "$%.2f", $0) } ?? "N/A",
            weekLow52: metrics.weekLow52.map { String(format: "$%.2f", $0) } ?? "N/A",
            eps: metrics.epsTTM.map { String(format: "$%.2f", $0) } ?? "N/A",
            avgVolume: avgVolumeStr,
            logoURL: profile.logo
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
