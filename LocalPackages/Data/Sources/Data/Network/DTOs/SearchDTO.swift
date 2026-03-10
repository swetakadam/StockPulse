//
//  SearchDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Outer wrapper

struct SymbolSearchResponse: Decodable {
    let bestMatches: [SymbolMatch]

    enum CodingKeys: String, CodingKey {
        case bestMatches = "bestMatches"
    }
}

// MARK: - Match payload

struct SymbolMatch: Decodable {
    let symbol: String
    let name: String
    let type: String
    let region: String
    let currency: String

    enum CodingKeys: String, CodingKey {
        case symbol   = "1. symbol"
        case name     = "2. name"
        case type     = "3. type"
        case region   = "4. region"
        case currency = "8. currency"
    }
}
