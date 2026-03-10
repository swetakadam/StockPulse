//
//  TimeSeriesDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Outer wrapper

struct TimeSeriesIntradayResponse: Decodable {
    let metadata: TimeSeriesMetadata
    let timeSeries: [String: TimeSeriesEntry]

    enum CodingKeys: String, CodingKey {
        case metadata   = "Meta Data"
        case timeSeries = "Time Series (5min)"
    }
}

// MARK: - Metadata

struct TimeSeriesMetadata: Decodable {
    let symbol: String
    let lastRefreshed: String
    let interval: String
    let outputSize: String

    enum CodingKeys: String, CodingKey {
        case symbol        = "2. Symbol"
        case lastRefreshed = "3. Last Refreshed"
        case interval      = "4. Interval"
        case outputSize    = "5. Output Size"
    }
}

// MARK: - Single candle entry

struct TimeSeriesEntry: Decodable {
    let open: String
    let high: String
    let low: String
    let close: String
    let volume: String

    enum CodingKeys: String, CodingKey {
        case open   = "1. open"
        case high   = "2. high"
        case low    = "3. low"
        case close  = "4. close"
        case volume = "5. volume"
    }
}
