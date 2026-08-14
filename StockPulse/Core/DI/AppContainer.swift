//
//  AppContainer.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import SwiftData
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

    var stockDetailViewModel: Factory<StockDetailViewModel> {
        self {
            StockDetailViewModel(
                fetchStockUseCase:           self.fetchStockUseCase(),
                fetchCompanyOverviewUseCase: self.fetchCompanyOverviewUseCase(),
                fetchTimeSeriesUseCase:      self.fetchTimeSeriesUseCase(),
                addToWatchlistUseCase:       self.addToWatchlistUseCase(),
                removeFromWatchlistUseCase:  self.removeFromWatchlistUseCase(),
                fetchWatchlistUseCase:       self.fetchWatchlistUseCase(),
                cache:                       self.stockCache()
            )
        }
    }

    // MARK: - Recent Search

    /// Recent search store — singleton so same instance app-wide
    var recentSearchStore: Factory<RecentSearchRepositoryProtocol> {
        self { RecentSearchStore() }
            .singleton
    }

    var fetchRecentSearchesUseCase: Factory<FetchRecentSearchesUseCaseProtocol> {
        self { FetchRecentSearchesUseCase(repository: self.recentSearchStore()) }
    }

    var saveRecentSearchUseCase: Factory<SaveRecentSearchUseCaseProtocol> {
        self { SaveRecentSearchUseCase(repository: self.recentSearchStore()) }
    }

    var clearRecentSearchesUseCase: Factory<ClearRecentSearchesUseCaseProtocol> {
        self { ClearRecentSearchesUseCase(repository: self.recentSearchStore()) }
    }

    // MARK: - Search ViewModel

    var searchViewModel: Factory<SearchViewModel> {
        self {
            SearchViewModel(
                searchStocksUseCase:        self.searchStocksUseCase(),
                addToWatchlistUseCase:      self.addToWatchlistUseCase(),
                fetchRecentSearchesUseCase: self.fetchRecentSearchesUseCase(),
                saveRecentSearchUseCase:    self.saveRecentSearchUseCase(),
                clearRecentSearchesUseCase: self.clearRecentSearchesUseCase()
            )
        }
    }

    // MARK: - Watchlist ViewModel

    var watchlistViewModel: Factory<WatchlistViewModel> {
        self {
            WatchlistViewModel(
                fetchWatchlistUseCase:      self.fetchWatchlistUseCase(),
                removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
                fetchStockUseCase:          self.fetchStockUseCase(),
                cache:                      self.stockCache()
            )
        }
    }

    // MARK: - Auth

    var authRepository: Factory<any AuthRepositoryProtocol> {
        self { AuthRepositoryImpl() }
            .singleton
    }

    var signInWithAppleUseCase: Factory<any SignInWithAppleUseCaseProtocol> {
        self { SignInWithAppleUseCase(repository: self.authRepository()) }
    }

    var getCurrentUserUseCase: Factory<any GetCurrentUserUseCaseProtocol> {
        self { GetCurrentUserUseCase(repository: self.authRepository()) }
    }

    var signOutUseCase: Factory<any SignOutUseCaseProtocol> {
        self { SignOutUseCase(repository: self.authRepository()) }
    }

    var authViewModel: Factory<AuthViewModel> {
        self { AuthViewModel(signInWithAppleUseCase: self.signInWithAppleUseCase()) }
    }

    var settingsViewModel: Factory<SettingsViewModel> {
        self {
            SettingsViewModel(
                getCurrentUserUseCase: self.getCurrentUserUseCase(),
                signOutUseCase:        self.signOutUseCase()
            )
        }
    }

    // MARK: - SEC / 10-K

    var azureChatClient: Factory<AzureChatClient> {
        self { AzureChatClient() }.singleton
    }

    var secRepository: Factory<any SECRepositoryProtocol> {
        self {
            let chatClient = self.azureChatClient()
            let parser = TenKParser { rawHTML, section in
                try await chatClient.parseSection(rawHTML: rawHTML, section: section)
            }
            return SECRepositoryImpl(client: SECClient(), parser: parser)
        }.singleton
    }

    var fetchTenKSectionUseCase: Factory<FetchTenKSectionUseCaseProtocol> {
        self { FetchTenKSectionUseCase(repository: self.secRepository()) }
    }

    // MARK: - Agent Infrastructure

    var agentModelContainer: Factory<ModelContainer> {
        self {
            try! ModelContainer(for: StoredAgentResult.self)
        }.singleton
    }

    var agentMemory: Factory<AgentMemory> {
        self { AgentMemory(container: self.agentModelContainer()) }.singleton
    }

    var agentToolRegistry: Factory<AgentToolRegistry> {
        self {
            AgentToolRegistry(
                fetchStockUseCase:          self.fetchStockUseCase(),
                searchStocksUseCase:        self.searchStocksUseCase(),
                fetchWatchlistUseCase:      self.fetchWatchlistUseCase(),
                addToWatchlistUseCase:      self.addToWatchlistUseCase(),
                removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
                fetchTenKSectionUseCase:    self.fetchTenKSectionUseCase()
            )
        }.singleton
    }

    var agentOrchestrator: Factory<AgentOrchestrator> {
        self {
            AgentOrchestrator(
                chatClient:   self.azureChatClient(),
                toolRegistry: self.agentToolRegistry(),
                memory:       self.agentMemory()
            )
        }.singleton
    }

    // MARK: - AI Assistant ViewModel

    var aiAssistantViewModel: Factory<AIAssistantViewModel> {
        self {
            AIAssistantViewModel(
                fetchStockUseCase:          self.fetchStockUseCase(),
                searchStocksUseCase:        self.searchStocksUseCase(),
                fetchWatchlistUseCase:      self.fetchWatchlistUseCase(),
                addToWatchlistUseCase:      self.addToWatchlistUseCase(),
                removeFromWatchlistUseCase: self.removeFromWatchlistUseCase(),
                agentOrchestrator:          self.agentOrchestrator()
            )
        }
    }
}
