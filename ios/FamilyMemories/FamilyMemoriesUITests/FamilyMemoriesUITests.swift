import XCTest

final class FamilyMemoriesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyTimelineShowsImportAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        XCTAssertTrue(app.staticTexts["timeline.empty.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["timeline.import"].exists)
    }

    @MainActor
    func testTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["tab.timeline"].exists)
        app.tabBars.buttons["tab.album"].tap()
        XCTAssertTrue(app.staticTexts["album.empty.title"].waitForExistence(timeout: 2))
        app.tabBars.buttons["tab.settings"].tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 2))
    }
}
