//
//  FetchTimeSeriesUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

public protocol FetchTimeSeriesUseCaseProtocol {
    func execute(symbol: String, range: TimeRange) async throws -> [PricePoint]
}
