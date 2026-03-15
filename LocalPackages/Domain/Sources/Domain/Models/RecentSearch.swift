//
//  RecentSearch.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation

public struct RecentSearch: Codable, Identifiable, Equatable {
    public var id: String { query }
    public let query: String
    public let searchedAt: Date

    public init(query: String, searchedAt: Date = Date()) {
        self.query = query
        self.searchedAt = searchedAt
    }
}
