//
//  RecentSearchStore.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import OSLog

/// Persists recent searches to UserDefaults.
/// Max 10 entries, newest first, no duplicates.
/// Registered in AppContainer via Factory.
public final class RecentSearchStore: RecentSearchRepositoryProtocol {

    private let defaults = UserDefaults.standard
    private let key = "recentSearches"
    private let maxCount = 10
    private let logger = Logger(
        subsystem: "com.sweta.stockpulse",
        category: "RecentSearch"
    )

    public init() {}

    public func fetchRecentSearches() -> [RecentSearch] {
        guard let data = defaults.data(forKey: key),
              let searches = try? JSONDecoder().decode([RecentSearch].self, from: data)
        else { return [] }
        return searches
    }

    public func saveRecentSearch(query: String) {
        var searches = fetchRecentSearches()
        // Remove duplicate if exists — will re-add at top
        searches.removeAll { $0.query.lowercased() == query.lowercased() }
        // Insert at top
        searches.insert(RecentSearch(query: query), at: 0)
        // Enforce max limit
        if searches.count > maxCount {
            searches = Array(searches.prefix(maxCount))
        }
        persist(searches)
        logger.debug("💾 Saved recent search: \(query)")
    }

    public func removeRecentSearch(query: String) {
        var searches = fetchRecentSearches()
        searches.removeAll { $0.query.lowercased() == query.lowercased() }
        persist(searches)
    }

    public func clearAllRecentSearches() {
        defaults.removeObject(forKey: key)
        logger.debug("💾 Cleared all recent searches")
    }

    private func persist(_ searches: [RecentSearch]) {
        guard let data = try? JSONEncoder().encode(searches) else { return }
        defaults.set(data, forKey: key)
    }
}
