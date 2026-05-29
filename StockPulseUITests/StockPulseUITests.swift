//
//  StockPulseUITests.swift
//  StockPulseUITests
//
//  Created by Sweta Kadam on 3/3/26.
//

import XCTest

final class StockPulseUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Test 1: App launches and shows Dashboard

    func testAppLaunchesAndShowsDashboard() {
        XCTAssert(app.staticTexts["StockPulse"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Markets"].waitForExistence(timeout: 5))
        XCTAssert(app.staticTexts["Trending"].waitForExistence(timeout: 5))
        takeScreenshot("Dashboard")
    }

    // MARK: - Test 2: Tab bar navigation works

    func testTabBarNavigationWorks() {
        app.tabBars.buttons["Watchlist"].tap()
        // SwiftUI List renders as UICollectionView under the hood, so
        // watchlist_list may live in collectionViews, tables, or
        // otherElements depending on iOS version. Match by identifier only.
        let watchlistList = app.descendants(matching: .any)
                               .matching(identifier: "watchlist_list").firstMatch
        let watchlistEmpty = app.otherElements["watchlist_empty_state"]
        let watchlistVisible =
            watchlistList.waitForExistence(timeout: 5) ||
            watchlistEmpty.waitForExistence(timeout: 5)
        XCTAssert(watchlistVisible)

        app.tabBars.buttons["Search"].tap()
        XCTAssert(app.searchFields.firstMatch.waitForExistence(timeout: 5))

        app.tabBars.buttons["Home"].tap()
        XCTAssert(app.staticTexts["StockPulse"].waitForExistence(timeout: 5))
        takeScreenshot("Tab Navigation")
    }

    // MARK: - Test 3: Search for a stock

    func testSearchForStock() {
        app.tabBars.buttons["Search"].tap()
        let searchBar = app.searchFields.firstMatch
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        searchBar.typeText("Apple")
        XCTAssert(app.otherElements["search_results_list"].waitForExistence(timeout: 10))
        takeScreenshot("Search Results")
    }

    // MARK: - Test 4: Search and navigate to Stock Detail

    func testSearchAndNavigateToStockDetail() {
        app.tabBars.buttons["Search"].tap()
        let searchBar = app.searchFields.firstMatch
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        // Company-name query — Finnhub /search returns reliable results.
        // Symbol-only queries can come back empty depending on rate limits.
        searchBar.typeText("Apple")
        XCTAssert(app.otherElements["search_results_list"].waitForExistence(timeout: 10))
        let aaplResult = appleResultElement()
        XCTAssert(aaplResult.waitForExistence(timeout: 5))
        tapLeftOf(aaplResult)
        XCTAssert(app.staticTexts["stock_symbol_label"].waitForExistence(timeout: 10))
        XCTAssert(app.staticTexts["stock_price_label"].exists)
        XCTAssert(app.buttons["watchlist_toggle_button"].exists)
        takeScreenshot("Stock Detail")
    }

    // MARK: - Test 5: Add stock to watchlist from Search

    func testAddStockToWatchlistFromSearch() {
        app.tabBars.buttons["Search"].tap()
        let searchBar = app.searchFields.firstMatch
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        searchBar.tap()
        searchBar.typeText("Apple")
        XCTAssert(app.otherElements["search_results_list"].waitForExistence(timeout: 10))
        let aaplResult = appleResultElement()
        XCTAssert(aaplResult.waitForExistence(timeout: 5))
        tapLeftOf(aaplResult)
        XCTAssert(app.buttons["watchlist_toggle_button"].waitForExistence(timeout: 5))
        app.buttons["watchlist_toggle_button"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
        }
        app.tabBars.buttons["Watchlist"].tap()
        let watchlistHasAAPL =
            app.cells["watchlist_row_AAPL"].waitForExistence(timeout: 5) ||
            app.staticTexts["AAPL"].waitForExistence(timeout: 5)
        XCTAssert(watchlistHasAAPL)
        takeScreenshot("Watchlist with AAPL")
    }

    /// Finds the AAPL row tappable element inside search results. SwiftUI's
    /// `.accessibilityIdentifier()` applied outside a custom Button doesn't
    /// always attach to the Button's accessibility element — the Button
    /// auto-derives its identifier from its label text instead. So fall back
    /// to label-matching: find a button whose label contains "AAPL".
    private func appleResultElement() -> XCUIElement {
        let list = app.otherElements["search_results_list"]
        // 1) Explicit identifier (works on some iOS versions)
        let byId = app.descendants(matching: .any)
                      .matching(identifier: "search_result_AAPL")
                      .firstMatch
        if byId.exists { return byId }
        // 2) Button whose label contains AAPL (the outer onTap button)
        let byLabel = list.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] 'AAPL'"))
            .firstMatch
        return byLabel
    }

    /// Tap the left third of the row so we hit the symbol/name area, never
    /// the trailing star button.
    private func tapLeftOf(_ element: XCUIElement) {
        let coord = element.coordinate(
            withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)
        )
        coord.tap()
    }

    // MARK: - Test 6: AI Assistant tab opens

    func testAIAssistantTabOpens() {
        app.tabBars.buttons["Assistant"].tap()
        XCTAssert(app.navigationBars["Stock Assistant"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["Start Voice Session"].waitForExistence(timeout: 5))
        takeScreenshot("AI Assistant")
    }

    // MARK: - Demo Recording Flow
    // Runs a paced walkthrough of every tab for screen-recording.
    // Not asserting much — the goal is reproducible navigation while
    // `xcrun simctl io booted recordVideo` captures the screen.

    func testDemoRecording() {
        // Dashboard — let the user see the loaded state
        XCTAssert(app.staticTexts["StockPulse"].waitForExistence(timeout: 5))
        sleep(3)

        // Search → type "Apple" (company-name query — Finnhub returns results
        // for these reliably; symbol-only queries can return empty)
        app.tabBars.buttons["Search"].tap()
        let searchBar = app.searchFields.firstMatch
        XCTAssert(searchBar.waitForExistence(timeout: 5))
        sleep(1)
        searchBar.tap()
        searchBar.typeText("Apple")
        XCTAssert(app.otherElements["search_results_list"].waitForExistence(timeout: 15))
        sleep(3) // let results render

        // Stock Detail — tap on the AAPL row's left side so we hit the
        // outer row Button, not the trailing star-add-to-watchlist button.
        let firstResult = appleResultElement()
        if firstResult.waitForExistence(timeout: 5) {
            tapLeftOf(firstResult)
            _ = app.staticTexts["stock_symbol_label"].waitForExistence(timeout: 10)
            sleep(3)

            // Add to watchlist
            if app.buttons["watchlist_toggle_button"].exists {
                app.buttons["watchlist_toggle_button"].tap()
                sleep(2)
            }

            // Back out of detail
            if app.navigationBars.buttons.firstMatch.exists {
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }

        // Watchlist tab
        app.tabBars.buttons["Watchlist"].tap()
        sleep(3)

        // AI Assistant tab (don't start session — just show entry screen)
        app.tabBars.buttons["Assistant"].tap()
        _ = app.buttons["Start Voice Session"].waitForExistence(timeout: 5)
        sleep(3)

        // Back to Dashboard for closing shot
        app.tabBars.buttons["Home"].tap()
        sleep(2)
    }

    /// First result row inside the search_results_list, regardless of which
    /// stock came back from the API. Robust for the demo flow.
    ///
    /// SearchResultRow has a nested star button inside its outer onTap Button,
    /// so tapping the row wrapper element can hit the inner button by accident.
    /// Tapping the symbol staticText (left side of the row) lands inside the
    /// outer Button's content but outside the inner star button.
    private func firstSearchResult() -> XCUIElement {
        let list = app.otherElements["search_results_list"]
        // Prefer the symbol staticText — it's part of the outer Button's label,
        // not the nested star button, so taps reliably trigger navigation.
        let symbolText = list.staticTexts
            .matching(NSPredicate(format: "label MATCHES '[A-Z]{1,5}'"))
            .firstMatch
        if symbolText.exists { return symbolText }
        // Fallback to any row identifier element.
        return list.descendants(matching: .any)
                   .matching(NSPredicate(format: "identifier BEGINSWITH 'search_result_'"))
                   .firstMatch
    }

    // MARK: - Helper

    private func takeScreenshot(_ name: String) {
        let screenshot = XCUIApplication().screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
