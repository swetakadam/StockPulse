//
//  SheetRoute.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

enum SheetRoute: Identifiable, Hashable {
    case addToWatchlist(symbol: String)
    case stockFilter
    case settings
    case authFlow

    var id: String {
        switch self {
        case .addToWatchlist(let symbol): return "addToWatchlist-\(symbol)"
        case .stockFilter:                return "stockFilter"
        case .settings:                   return "settings"
        case .authFlow:                   return "authFlow"
        }
    }
}
