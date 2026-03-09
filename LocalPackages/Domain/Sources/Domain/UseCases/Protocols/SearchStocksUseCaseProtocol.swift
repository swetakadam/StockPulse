//
//  SearchStocksUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

public protocol SearchStocksUseCaseProtocol {
    func execute(query: String) async throws -> [Stock]
}
