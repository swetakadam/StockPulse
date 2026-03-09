//
//  AppRoute.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// TODO: Add Universal Link / deep link routing cases once AppCoordinator onOpenURL is wired
enum AppRoute: Hashable {
    case stockDetail(symbol: String)
    case watchlist
    case auth
    case search
}
