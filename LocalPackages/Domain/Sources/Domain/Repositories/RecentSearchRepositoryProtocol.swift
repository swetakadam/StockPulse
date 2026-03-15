//
//  RecentSearchRepositoryProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol RecentSearchRepositoryProtocol {
    func fetchRecentSearches() -> [RecentSearch]
    func saveRecentSearch(query: String)
    func removeRecentSearch(query: String)
    func clearAllRecentSearches()
}
