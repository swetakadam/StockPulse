//
//  SaveRecentSearchUseCaseTests.swift
//  DomainTests
//

import Testing
import Foundation
@testable import Domain

final class MockRecentSearchRepository: RecentSearchRepositoryProtocol {
    var searches: [RecentSearch] = []
    var saveCallCount = 0
    var clearCallCount = 0

    func fetchRecentSearches() -> [RecentSearch] { searches }

    func saveRecentSearch(query: String) {
        saveCallCount += 1
        searches.removeAll { $0.query.lowercased() == query.lowercased() }
        searches.insert(RecentSearch(query: query), at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
    }

    func removeRecentSearch(query: String) {
        searches.removeAll { $0.query == query }
    }

    func clearAllRecentSearches() {
        clearCallCount += 1
        searches.removeAll()
    }
}

@Suite("SaveRecentSearchUseCase")
struct SaveRecentSearchUseCaseTests {

    @Test("Saves valid query")
    func savesValidQuery() {
        let repo = MockRecentSearchRepository()
        let sut = SaveRecentSearchUseCase(repository: repo)

        sut.execute(query: "AAPL")

        #expect(repo.saveCallCount == 1)
        #expect(repo.searches.first?.query == "AAPL")
    }

    @Test("Ignores empty query")
    func ignoresEmptyQuery() {
        let repo = MockRecentSearchRepository()
        let sut = SaveRecentSearchUseCase(repository: repo)

        sut.execute(query: "   ")

        #expect(repo.saveCallCount == 0)
    }

    @Test("Deduplicates — moves existing query to top")
    func deduplicatesExistingQuery() {
        let repo = MockRecentSearchRepository()
        repo.searches = [RecentSearch(query: "MSFT"), RecentSearch(query: "AAPL")]
        let sut = SaveRecentSearchUseCase(repository: repo)

        sut.execute(query: "AAPL")

        #expect(repo.searches.first?.query == "AAPL")
        #expect(repo.searches.count == 2)
    }

    @Test("Enforces max 10 recent searches")
    func enforcesMax10Searches() {
        let repo = MockRecentSearchRepository()
        let sut = SaveRecentSearchUseCase(repository: repo)

        for i in 0..<11 { sut.execute(query: "STOCK\(i)") }

        #expect(repo.searches.count == 10)
    }
}
