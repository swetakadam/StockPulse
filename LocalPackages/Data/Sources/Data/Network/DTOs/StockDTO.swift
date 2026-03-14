//
//  StockDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Finnhub /quote response.
/// All fields are Double — no string parsing required.
struct FinnhubQuoteDTO: Decodable {
    let current:       Double  // c — current price
    let change:        Double  // d — change
    let changePercent: Double  // dp — change percent
    let high:          Double  // h — day high
    let low:           Double  // l — day low
    let open:          Double  // o — day open
    let previousClose: Double  // pc — previous close

    enum CodingKeys: String, CodingKey {
        case current       = "c"
        case change        = "d"
        case changePercent = "dp"
        case high          = "h"
        case low           = "l"
        case open          = "o"
        case previousClose = "pc"
    }
}
