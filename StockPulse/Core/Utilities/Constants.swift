//
//  Constants.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// TODO: Read ALPHAVANTAGE_BASE_URL from Bundle (via xcconfig) instead of hardcoding
enum Constants {
    enum API {
        /// Resolved at runtime from Info.plist / xcconfig — never hardcode.
        static var baseURL: String {
            // TODO: Replace with Bundle.main.infoDictionary["ALPHAVANTAGE_BASE_URL"] as? String ?? ""
            return "https://www.alphavantage.co/query"
        }

        static var apiKey: String {
            // TODO: Replace with Bundle.main.infoDictionary["ALPHAVANTAGE_API_KEY"] as? String ?? ""
            return ""
        }
    }

    enum Watchlist {
        static let maxItems = 50    // TODO: Confirm product limit
    }
}
