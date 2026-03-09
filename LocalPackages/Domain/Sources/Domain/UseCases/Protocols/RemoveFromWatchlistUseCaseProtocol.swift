//
//  RemoveFromWatchlistUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol RemoveFromWatchlistUseCaseProtocol {
    func execute(symbol: String) async throws
}
