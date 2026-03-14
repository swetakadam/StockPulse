//
//  FetchCompanyOverviewUseCaseProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

public protocol FetchCompanyOverviewUseCaseProtocol {
    func execute(symbol: String) async throws -> CompanyOverview
}
