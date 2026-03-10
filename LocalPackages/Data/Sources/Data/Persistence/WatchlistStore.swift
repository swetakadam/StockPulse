//
//  WatchlistStore.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

// MARK: - Protocol

public protocol WatchlistStoreProtocol {
    func load() -> [String]
    func save(symbols: [String])
    func add(symbol: String)
    func remove(symbol: String)
    func contains(symbol: String) -> Bool
}

// MARK: - UserDefaults implementation

public final class UserDefaultsWatchlistStore: WatchlistStoreProtocol {
    public init() {}

    private let key = "stockpulse_watchlist_symbols"
    private let queue = DispatchQueue(label: "com.sweta.stockpulse.watchliststore")

    public func load() -> [String] {
        queue.sync {
            UserDefaults.standard.stringArray(forKey: key) ?? []
        }
    }

    public func save(symbols: [String]) {
        queue.sync {
            UserDefaults.standard.set(symbols, forKey: key)
        }
    }

    public func add(symbol: String) {
        queue.sync {
            var current = UserDefaults.standard.stringArray(forKey: key) ?? []
            guard !current.contains(symbol) else { return }
            current.append(symbol)
            UserDefaults.standard.set(current, forKey: key)
        }
    }

    public func remove(symbol: String) {
        queue.sync {
            var current = UserDefaults.standard.stringArray(forKey: key) ?? []
            current.removeAll { $0 == symbol }
            UserDefaults.standard.set(current, forKey: key)
        }
    }

    public func contains(symbol: String) -> Bool {
        load().contains(symbol)
    }
}
