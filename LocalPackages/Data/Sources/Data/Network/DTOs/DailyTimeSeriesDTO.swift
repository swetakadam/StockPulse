//
//  DailyTimeSeriesDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Finnhub /stock/candle response (daily resolution).
/// status == "no_data" means the symbol has no data for the requested range.
struct FinnhubCandleDTO: Decodable {
    let closes:     [Double]  // c
    let highs:      [Double]  // h
    let lows:       [Double]  // l
    let opens:      [Double]  // o
    let timestamps: [Int]     // t — UNIX seconds
    let status:     String    // s — "ok" or "no_data"

    enum CodingKeys: String, CodingKey {
        case closes     = "c"
        case highs      = "h"
        case lows       = "l"
        case opens      = "o"
        case timestamps = "t"
        case status     = "s"
    }
}
