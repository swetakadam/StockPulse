//
//  AppContainer.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Factory

// TODO: Register all concrete implementations; add scoped/singleton lifetimes where appropriate
extension Container {

    // MARK: - Network
    var apiClient: Factory<APIClientProtocol> {
        self { APIClient() }
    }

    // MARK: - Repositories
    var stockRepository: Factory<StockRepositoryProtocol> {
        self { StockRepositoryImpl(apiClient: self.apiClient()) }
    }

    var watchlistRepository: Factory<WatchlistRepositoryProtocol> {
        self { WatchlistRepositoryImpl(store: WatchlistStore()) }
    }

    // MARK: - Use Cases
    var fetchStockUseCase: Factory<FetchStockUseCaseProtocol> {
        self { FetchStockUseCase(repository: self.stockRepository()) }
    }

    var fetchQuoteUseCase: Factory<FetchQuoteUseCaseProtocol> {
        self { FetchQuoteUseCase(repository: self.stockRepository()) }
    }

    var searchStocksUseCase: Factory<SearchStocksUseCaseProtocol> {
        self { SearchStocksUseCase(repository: self.stockRepository()) }
    }

    var manageWatchlistUseCase: Factory<ManageWatchlistUseCaseProtocol> {
        self { ManageWatchlistUseCase(repository: self.watchlistRepository()) }
    }
}
