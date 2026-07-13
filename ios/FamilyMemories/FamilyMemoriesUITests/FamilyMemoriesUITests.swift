import XCTest

final class FamilyMemoriesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Locates a tab bar button by its accessibility label across device families.
    /// - On iPhone: tabs are buttons inside the standard `XCUIElementTypeTabBar`.
    /// - On iPad (iPadOS 18+ floating tab bar): tabs expose nested duplicate buttons
    ///   (parent `_UIFloatingTabBarItemCell`, child `_UIFloatingTabBarItemView` both
    ///   advertise Button traits with the same label). We use `firstMatch` to resolve
    ///   the ambiguity rather than crashing on "Multiple matching elements found".
    private func tabButton(_ label: String, in app: XCUIApplication) -> XCUIElement {
        if app.tabBars.buttons[label].exists { return app.tabBars.buttons[label] }
        if app.cells[label].exists { return app.cells[label] }
        // iPad floating tab bar: buttons may be nested with duplicate labels
        return app.buttons.matching(
            NSPredicate(format: "label == %@", label)
        ).firstMatch
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

        XCTAssertTrue(tabButton("时间线", in: app).exists)
        tabButton("相册", in: app).tap()
        XCTAssertTrue(app.staticTexts["还没有回忆"].waitForExistence(timeout: 2))
        tabButton("设置", in: app).tap()
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLanguageSwitchChangesUiCopy() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        tabButton("设置", in: app).tap()
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

        tabButton("设置", in: app).tap()

        XCTAssertTrue(app.buttons["导入 Web JSON"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsResetShowsDestructiveConfirmation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        tabButton("设置", in: app).tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["清除本地数据"].waitForExistence(timeout: 2))
        app.buttons["清除本地数据"].tap()

        XCTAssertTrue(app.alerts["清除所有本地数据？"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.alerts.buttons["清除"].exists)
        XCTAssertTrue(app.alerts.buttons["取消"].exists)
    }
}
