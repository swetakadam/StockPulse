//
//  SearchDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Finnhub /search response.
struct FinnhubSearchResponse: Decodable {
    let count:  Int
    let result: [FinnhubSearchResult]
}

/// A single search match from Finnhub.
struct FinnhubSearchResult: Decodable {
    let symbol:      String
    let description: String
    let type:        String?
}
