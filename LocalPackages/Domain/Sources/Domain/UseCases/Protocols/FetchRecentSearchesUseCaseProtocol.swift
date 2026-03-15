//
//  FetchRecentSearchesUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol FetchRecentSearchesUseCaseProtocol {
    func execute() -> [RecentSearch]
}
