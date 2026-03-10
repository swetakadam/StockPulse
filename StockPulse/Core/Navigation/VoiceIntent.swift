//
//  VoiceIntent.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

/// Future AI voice assistant intents.
enum VoiceIntent {
    case navigate(AppRoute)
    case search(query: String)
    case addToWatchlist(symbol: String)
    case removeFromWatchlist(symbol: String)
    case dismiss
    case goBack
    case goHome
    case unknown(rawText: String)
}
