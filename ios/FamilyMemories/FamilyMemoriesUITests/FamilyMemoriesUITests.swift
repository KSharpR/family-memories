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

        XCTAssertTrue(app.staticTexts["开始整理家族回忆"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["导入照片"].exists)
    }

    @MainActor
    func testTabsAreReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["时间线"].exists)
        app.tabBars.buttons["相册"].tap()
        XCTAssertTrue(app.staticTexts["还没有回忆"].waitForExistence(timeout: 2))
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLanguageSwitchChangesUiCopy() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["导出备份"].exists)

        app.buttons["English"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Export backup"].exists)

        app.buttons["中文"].tap()
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["导出备份"].exists)
    }

    @MainActor
    func testSettingsShowsWebJsonImportAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        app.tabBars.buttons["设置"].tap()

        XCTAssertTrue(app.buttons["导入 Web JSON"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsResetShowsDestructiveConfirmation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        app.tabBars.buttons["设置"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["清除本地数据"].waitForExistence(timeout: 2))
        app.buttons["清除本地数据"].tap()

        XCTAssertTrue(app.alerts["清除所有本地数据？"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.alerts.buttons["清除"].exists)
        XCTAssertTrue(app.alerts.buttons["取消"].exists)
    }
}
