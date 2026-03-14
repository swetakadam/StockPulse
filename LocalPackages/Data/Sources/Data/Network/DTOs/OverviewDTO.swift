//
//  OverviewDTO.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Finnhub /stock/profile2 response.
struct FinnhubProfileDTO: Decodable {
    let name:                 String?
    let ticker:               String?
    let finnhubIndustry:      String?
    let marketCapitalization: Double?  // in millions USD
    let weburl:               String?
    let logo:                 String?
}
