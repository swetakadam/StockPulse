//
//  StockMapper.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain

enum StockMapper {

    // MARK: - Search result → Stock (no live price available)

    static func toStock(from match: SymbolMatch) -> Stock {
        Stock(
            id: match.symbol,
            symbol: match.symbol,
            companyName: match.name,
            currentPrice: 0,
            change: 0,
            changePercent: 0,
            volume: 0,
            marketCap: 0,
            logoURL: nil
        )
    }

    // MARK: - GlobalQuote → Quote? (nil if price string is unparseable)

    static func toQuote(from quote: GlobalQuote) -> Quote? {
        guard let price  = Double(quote.price),
              let high   = Double(quote.high),
              let low    = Double(quote.low),
              let open   = Double(quote.open),
              let volume = Int(quote.volume),
              let change = Double(quote.change)
        else { return nil }

        // Strip trailing "%" before parsing changePercent
        let percentString = quote.changePercent
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let changePercent = Double(percentString) else { return nil }

        return Quote(
            symbol: quote.symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            timestamp: Date(),          // Alpha Vantage free tier has no live timestamp
            volume: volume,
            high: high,
            low: low,
            open: open
        )
    }

    // MARK: - GlobalQuote → Stock (marketCap not available from GLOBAL_QUOTE)

    static func toStock(from quote: GlobalQuote) -> Stock {
        let price         = Double(quote.price)  ?? 0
        let change        = Double(quote.change) ?? 0
        let volume        = Int(quote.volume)    ?? 0
        let percentString = quote.changePercent
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        let changePercent = Double(percentString) ?? 0

        return Stock(
            id: quote.symbol,
            symbol: quote.symbol,
            companyName: quote.symbol,  // GLOBAL_QUOTE doesn't return company name
            currentPrice: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            marketCap: 0,               // not available from GLOBAL_QUOTE
            logoURL: nil
        )
    }
}
