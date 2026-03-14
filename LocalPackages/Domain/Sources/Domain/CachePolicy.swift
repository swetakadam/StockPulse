//
//  CachePolicy.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

import Foundation

public enum CachePolicy {
    case freeTier    // 25 calls/day — aggressive cache, sequential fetch
    case premiumTier // unlimited — short cache, concurrent fetch

    /// Single source of truth.
    /// To upgrade: change .freeTier to .premiumTier here.
    /// Everything else (TTL, fetch strategy, delay) updates automatically.
    public static let current: CachePolicy = .freeTier

    /// Cache TTL in seconds
    public var cacheTTL: TimeInterval {
        switch self {
        case .freeTier:    return 86_400  // 24 hours
        case .premiumTier: return 60      // 1 minute
        }
    }

    /// Whether to fetch stocks concurrently
    public var useConcurrentFetching: Bool {
        switch self {
        case .freeTier:    return false
        case .premiumTier: return true
        }
    }

    /// Delay between sequential requests (free tier only)
    public var requestDelay: UInt64 {
        switch self {
        case .freeTier:    return 300_000_000  // 300ms
        case .premiumTier: return 0
        }
    }
}
