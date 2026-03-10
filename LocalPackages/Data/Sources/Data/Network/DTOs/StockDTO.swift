//
//  StockDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Outer wrapper

struct GlobalQuoteResponse: Decodable {
    let globalQuote: GlobalQuote

    enum CodingKeys: String, CodingKey {
        case globalQuote = "Global Quote"
    }
}

// MARK: - Quote payload

struct GlobalQuote: Decodable {
    let symbol: String
    let open: String
    let high: String
    let low: String
    let price: String
    let volume: String
    let latestTradingDay: String
    let previousClose: String
    let change: String
    let changePercent: String   // e.g. "1.25%"

    enum CodingKeys: String, CodingKey {
        case symbol           = "01. symbol"
        case open             = "02. open"
        case high             = "03. high"
        case low              = "04. low"
        case price            = "05. price"
        case volume           = "06. volume"
        case latestTradingDay = "07. latest trading day"
        case previousClose    = "08. previous close"
        case change           = "09. change"
        case changePercent    = "10. change percent"
    }
}
