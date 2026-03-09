//
//  FetchWatchlistUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol FetchWatchlistUseCaseProtocol {
    func execute() async throws -> [WatchlistItem]
}
