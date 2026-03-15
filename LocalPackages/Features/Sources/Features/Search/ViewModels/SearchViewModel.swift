//
//  SearchViewModel.swift
//  StockPulse
//
//  Created by Sweta Kadam on 3/3/26.
//

import Foundation
import Domain
import OSLog

// MARK: - Protocol

public protocol SearchViewModelProtocol: ObservableObject {
    var query:           String          { get set }
    var results:         [Stock]         { get }
    var recentSearches:  [RecentSearch]  { get }
    var trendingSymbols: [String]        { get }
    var isLoading:       Bool            { get }
    var error:           String?         { get }
    @MainActor func search(query: String) async
    @MainActor func clearRecentSearches()
    @MainActor func removeRecentSearch(_ query: String)
    @MainActor func addToWatchlist(symbol: String) async
}

// MARK: - ViewModel

public final class SearchViewModel: ObservableObject, SearchViewModelProtocol {

    private let searchStocksUseCase:        any SearchStocksUseCaseProtocol
    private let addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol
    private let fetchRecentSearchesUseCase: any FetchRecentSearchesUseCaseProtocol
    private let saveRecentSearchUseCase:    any SaveRecentSearchUseCaseProtocol
    private let clearRecentSearchesUseCase: any ClearRecentSearchesUseCaseProtocol
    private let logger = Logger(subsystem: "com.sweta.stockpulse", category: "Search")

    @Published public var query: String = ""
    @Published public private(set) var results:        [Stock]        = []
    @Published public private(set) var recentSearches: [RecentSearch] = []
    @Published public private(set) var isLoading:      Bool           = false
    @Published public private(set) var error:          String?

    public let trendingSymbols = [
        "AAPL", "MSFT", "GOOGL", "TSLA",
        "NVDA", "META", "AMZN", "BRK.B"
    ]

    private var searchTask: Task<Void, Never>?

    public init(
        searchStocksUseCase:        any SearchStocksUseCaseProtocol,
        addToWatchlistUseCase:      any AddToWatchlistUseCaseProtocol,
        fetchRecentSearchesUseCase: any FetchRecentSearchesUseCaseProtocol,
        saveRecentSearchUseCase:    any SaveRecentSearchUseCaseProtocol,
        clearRecentSearchesUseCase: any ClearRecentSearchesUseCaseProtocol
    ) {
        self.searchStocksUseCase        = searchStocksUseCase
        self.addToWatchlistUseCase      = addToWatchlistUseCase
        self.fetchRecentSearchesUseCase = fetchRecentSearchesUseCase
        self.saveRecentSearchUseCase    = saveRecentSearchUseCase
        self.clearRecentSearchesUseCase = clearRecentSearchesUseCase
        loadRecentSearches()
    }

    // MARK: - Search with debounce

    @MainActor public func search(query: String) async {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            isLoading = false
            error = nil
            return
        }

        searchTask = Task {
            do {
                // Debounce: 300ms after last keystroke
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }

                isLoading = true
                error = nil

                let searchResults = try await searchStocksUseCase.execute(query: trimmed)
                guard !Task.isCancelled else { return }

                results = searchResults
                saveRecentSearchUseCase.execute(query: trimmed)
                loadRecentSearches()
                logger.debug("🔍 Search '\(trimmed)': \(searchResults.count) results")
            } catch is CancellationError {
                // Debounce cancelled — new keystroke, ignore
            } catch {
                guard !Task.isCancelled else { return }
                self.error = "Search failed. Please try again."
                results = []
                logger.error("🔍 Search failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
        await searchTask?.value
    }

    // MARK: - Watchlist

    @MainActor public func addToWatchlist(symbol: String) async {
        try? await addToWatchlistUseCase.execute(symbol: symbol)
        logger.debug("⭐ Added to watchlist from search: \(symbol)")
    }

    // MARK: - Recent Searches

    @MainActor public func clearRecentSearches() {
        clearRecentSearchesUseCase.execute()
        loadRecentSearches()
    }

    @MainActor public func removeRecentSearch(_ query: String) {
        clearRecentSearchesUseCase.executeOne(query: query)
        loadRecentSearches()
    }

    private func loadRecentSearches() {
        recentSearches = fetchRecentSearchesUseCase.execute()
    }
}
