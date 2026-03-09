//
//  AddToWatchlistUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol AddToWatchlistUseCaseProtocol {
    func execute(symbol: String) async throws
}
