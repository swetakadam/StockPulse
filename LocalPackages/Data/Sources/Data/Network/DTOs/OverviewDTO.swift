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

/// Finnhub /stock/metric?metric=all response.
struct FinnhubMetricsResponse: Decodable {
    let metric: FinnhubMetricData
}

struct FinnhubMetricData: Decodable {
    let weekHigh52:           Double?
    let weekLow52:            Double?
    let avgVolume10Day:       Double?
    let epsTTM:               Double?
    let marketCapitalization: Double?
    let peRatio:              Double?

    enum CodingKeys: String, CodingKey {
        case weekHigh52           = "52WeekHigh"
        case weekLow52            = "52WeekLow"
        case avgVolume10Day       = "10DayAverageTradingVolume"
        case epsTTM               = "epsTTM"
        case marketCapitalization = "marketCapitalization"
        case peRatio              = "peBasicExclExtraTTM"
    }
}
