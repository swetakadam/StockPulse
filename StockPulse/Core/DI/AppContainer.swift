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
        self { try! FinnhubClient(bundle: Bundle.main) }
            .singleton
    }

    // MARK: - Persistence
    var watchlistStore: Factory<WatchlistStoreProtocol> {
        self { UserDefaultsWatchlistStore() }
    }

    /// Cache — singleton scope so same instance is shared across the app.
    /// Factory manages lifecycle (not a Swift static singleton).
    /// To use mock in tests: Container.shared.stockCache.register { MockStockCache() }
    var stockCache: Factory<StockCacheProtocol> {
        self { StockCache() }
            .singleton
    }

    // MARK: - Repositories
    var stockRepository: Factory<StockRepositoryProtocol> {
        self {
            StockRepositoryImpl(
                apiClient: self.apiClient(),
                watchlistStore: self.watchlistStore(),
                cache: self.stockCache()
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

    var fetchCompanyOverviewUseCase: Factory<FetchCompanyOverviewUseCaseProtocol> {
        self { FetchCompanyOverviewUseCase(repository: self.stockRepository()) }
    }

    var fetchTimeSeriesUseCase: Factory<FetchTimeSeriesUseCaseProtocol> {
        self { FetchTimeSeriesUseCase(repository: self.stockRepository()) }
    }

    // MARK: - ViewModels
    var dashboardViewModel: Factory<DashboardViewModel> {
        self {
            DashboardViewModel(
                fetchStockUseCase:     self.fetchStockUseCase(),
                fetchWatchlistUseCase: self.fetchWatchlistUseCase(),
                cache:                 self.stockCache()
            )
        }
    }

    var stockDetailViewModel: ParameterFactory<String, StockDetailViewModel> {
        self { symbol in
            StockDetailViewModel(
                symbol:                      symbol,
                fetchStockUseCase:           self.fetchStockUseCase(),
                fetchCompanyOverviewUseCase: self.fetchCompanyOverviewUseCase(),
                fetchTimeSeriesUseCase:      self.fetchTimeSeriesUseCase(),
                fetchWatchlistUseCase:       self.fetchWatchlistUseCase(),
                addToWatchlistUseCase:       self.addToWatchlistUseCase(),
                removeFromWatchlistUseCase:  self.removeFromWatchlistUseCase()
            )
        }
    }
}
