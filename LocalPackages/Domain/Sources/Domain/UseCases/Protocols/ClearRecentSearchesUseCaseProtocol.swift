//
//  ClearRecentSearchesUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol ClearRecentSearchesUseCaseProtocol {
    func execute()
    func executeOne(query: String)
}
