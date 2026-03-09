//
//  FetchStockUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol FetchStockUseCaseProtocol {
    func execute(symbol: String) async throws -> Stock
}
