//
//  AppContainer.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Factory
import Domain
import Data
import Features

extension Container {

    // MARK: - Network
    var apiClient: Factory<APIClientProtocol> {
        self { try! AlphaVantageClient() }
    }

    // MARK: - Persistence
    var watchlistStore: Factory<WatchlistStoreProtocol> {
        self { UserDefaultsWatchlistStore() }
    }

    // MARK: - Repositories
    var stockRepository: Factory<StockRepositoryProtocol> {
        self {
            StockRepositoryImpl(
                apiClient: self.apiClient(),
                watchlistStore: self.watchlistStore()
            )
        }
    }

    // MARK: - Use Cases
    var fetchStockUseCase: Factory<FetchStockUseCaseProtocol> {
        self { FetchStockUseCase(repository: self.stockRepository()) }
    }

    var searchStocksUseCase: Factory<SearchStocksUseCaseProtocol> {
        self { SearchStocksUseCase(repository: self.stockRepository()) }
    }

    var fetchWatchlistUseCase: Factory<FetchWatchlistUseCaseProtocol> {
        self { FetchWatchlistUseCase(repository: self.stockRepository()) }
    }

    var addToWatchlistUseCase: Factory<AddToWatchlistUseCaseProtocol> {
        self { AddToWatchlistUseCase(repository: self.stockRepository()) }
    }

    var removeFromWatchlistUseCase: Factory<RemoveFromWatchlistUseCaseProtocol> {
        self { RemoveFromWatchlistUseCase(repository: self.stockRepository()) }
    }

    // MARK: - ViewModels
    var dashboardViewModel: Factory<DashboardViewModel> {
        self {
            DashboardViewModel(
                fetchStockUseCase:     self.fetchStockUseCase(),
                fetchWatchlistUseCase: self.fetchWatchlistUseCase()
            )
        }
    }
}
