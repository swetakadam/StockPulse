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
        let watchlistVisible =
            app.tables["watchlist_list"].waitForExistence(timeout: 5) ||
            app.otherElements["watchlist_empty_state"].waitForExistence(timeout: 5)
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
        searchBar.typeText("AAPL")
        XCTAssert(app.buttons["search_result_AAPL"].waitForExistence(timeout: 10))
        app.buttons["search_result_AAPL"].tap()
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
        searchBar.typeText("AAPL")
        XCTAssert(app.buttons["search_result_AAPL"].waitForExistence(timeout: 10))
        app.buttons["search_result_AAPL"].tap()
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

    // MARK: - Test 6: AI Assistant tab opens

    func testAIAssistantTabOpens() {
        app.tabBars.buttons["Assistant"].tap()
        XCTAssert(app.navigationBars["Stock Assistant"].waitForExistence(timeout: 5))
        XCTAssert(app.buttons["Start Voice Session"].waitForExistence(timeout: 5))
        takeScreenshot("AI Assistant")
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
