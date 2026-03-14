//
//  StockCacheProtocol.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

// Pure Swift — zero framework imports

/// Protocol for stock cache — enables mock injection in tests.
/// Registered in AppContainer as Factory .singleton scope.
/// Lives in Domain so both Data (StockCache) and Features (DashboardViewModel)
/// can reference it without creating a Data → Features dependency.
public protocol StockCacheProtocol {
    func stock(for symbol: String) -> Stock?
    func save(_ stock: Stock)
    func invalidate(symbol: String)
    func invalidateAll()
}
