//
//  StockCache.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import OSLog

/// Thread-safe in-memory + UserDefaults cache for Stock data.
/// Registered in AppContainer as Factory .singleton scope.
/// Do NOT add static shared — Factory manages the instance lifecycle.
///
/// Free tier:    24hr TTL — preserves 25 calls/day budget.
/// Premium tier: 60s TTL  — near real-time data.
public final class StockCache: StockCacheProtocol {

    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "Cache"
    )
    private let defaults = UserDefaults.standard
    private let policy: CachePolicy
    private let queue = DispatchQueue(
        label: "com.sweta.stockpulse.cache",
        attributes: .concurrent
    )

    // In-memory layer (fastest — lives for app session)
    private var memoryCache: [String: CachedStock] = [:]

    /// Injectable init — policy defaults to CachePolicy.current
    public init(policy: CachePolicy = .current) {
        self.policy = policy
    }

    // MARK: - StockCacheProtocol

    public func stock(for symbol: String) -> Stock? {
        // Step 1: Read only — no mutations
        let result: (stock: Stock?, shouldPromote: CachedStock?) = queue.sync {
            // Check memory first
            if let cached = memoryCache[symbol],
               !cached.isExpired(ttl: policy.cacheTTL) {
                logger.debug("💾 Memory HIT: \(symbol)")
                return (cached.stock, nil)
            }
            // Check disk
            if let cached = loadFromDisk(symbol: symbol),
               !cached.isExpired(ttl: policy.cacheTTL) {
                logger.debug("💾 Disk HIT: \(symbol)")
                return (cached.stock, cached) // signal promotion needed
            }
            logger.debug("🌐 Cache MISS: \(symbol)")
            return (nil, nil)
        }

        // Step 2: Promote disk hit to memory — separate barrier write
        if let toPromote = result.shouldPromote {
            queue.sync(flags: .barrier) { [weak self] in
                self?.memoryCache[toPromote.stock.symbol] = toPromote
            }
        }

        return result.stock
    }

    public func save(_ stock: Stock) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }
            let cached = CachedStock(stock: stock, cachedAt: Date())
            self.memoryCache[stock.symbol] = cached
            self.saveToDisk(cached, symbol: stock.symbol)
            self.logger.debug("💾 Saved: \(stock.symbol) TTL:\(self.policy.cacheTTL)s")
        }
    }

    public func invalidate(symbol: String) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.memoryCache.removeValue(forKey: symbol)
            self.defaults.removeObject(forKey: self.diskKey(symbol))
            self.logger.debug("💾 Invalidated: \(symbol)")
        }
    }

    public func invalidateAll() {
        queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.memoryCache.removeAll()
            self.defaults.dictionaryRepresentation().keys
                .filter { $0.hasPrefix("stockcache.") }
                .forEach { self.defaults.removeObject(forKey: $0) }
            self.logger.debug("💾 Full cache invalidated")
        }
    }

    // MARK: - Private

    private struct CachedStock: Codable {
        let stock: Stock
        let cachedAt: Date

        func isExpired(ttl: TimeInterval) -> Bool {
            Date().timeIntervalSince(cachedAt) > ttl
        }
    }

    private func diskKey(_ symbol: String) -> String {
        "stockcache.\(symbol.lowercased())"
    }

    private func saveToDisk(_ cached: CachedStock, symbol: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(cached) else { return }
        defaults.set(data, forKey: diskKey(symbol))
    }

    private func loadFromDisk(symbol: String) -> CachedStock? {
        guard let data = defaults.data(forKey: diskKey(symbol)) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(CachedStock.self, from: data)
    }
}
