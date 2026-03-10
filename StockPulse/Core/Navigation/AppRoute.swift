//
//  AppRoute.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

enum AppRoute: Hashable {
    case dashboard
    case stockDetail(symbol: String)
    case search
    case watchlist
    case notifications
    case notification(userInfo: [String: String])
}
