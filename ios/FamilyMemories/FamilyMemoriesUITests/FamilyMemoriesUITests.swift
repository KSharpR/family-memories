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

    /// Takes a screenshot and attaches it with `.deleteOnSuccess` lifetime.
    private func attachScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
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

    // MARK: - Orientation smoke test

    @MainActor
    func testOrientationSmoke() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data"]
        app.launch()

        // Restore portrait during teardown so we never leak orientation state.
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        // --- Portrait ---
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["开始整理家族回忆"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["导入照片"].exists)
        attachScreenshot(named: "Portrait - Timeline")

        // --- Landscape ---
        XCUIDevice.shared.orientation = .landscapeRight
        // Use an observable orientation predicate rather than an arbitrary sleep.
        let landscapePredicate = NSPredicate { _, _ in
            XCUIDevice.shared.orientation == .landscapeRight
        }
        let landscapeExpectation = XCTNSPredicateExpectation(
            predicate: landscapePredicate, object: nil
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [landscapeExpectation], timeout: 3),
            .completed,
            "Device should have rotated to landscape"
        )
        // Confirm the UI has settled by verifying the empty state again.
        XCTAssertTrue(app.staticTexts["开始整理家族回忆"].waitForExistence(timeout: 5))
        attachScreenshot(named: "Landscape - Timeline")

        // Tab navigation in landscape.
        tabButton("相册", in: app).tap()
        XCTAssertTrue(app.staticTexts["还没有回忆"].waitForExistence(timeout: 2))

        tabButton("设置", in: app).tap()
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["导出备份"].exists)
        attachScreenshot(named: "Landscape - Settings")

        // --- Rotate back to portrait ---
        XCUIDevice.shared.orientation = .portrait
        let portraitPredicate = NSPredicate { _, _ in
            XCUIDevice.shared.orientation == .portrait
        }
        let portraitExpectation = XCTNSPredicateExpectation(
            predicate: portraitPredicate, object: nil
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [portraitExpectation], timeout: 3),
            .completed,
            "Device should have rotated back to portrait"
        )
        // Verify a representative element remains reachable.
        XCTAssertTrue(app.staticTexts["设置"].waitForExistence(timeout: 5))
        // Navigate back to Timeline.
        tabButton("时间线", in: app).tap()
        XCTAssertTrue(app.staticTexts["开始整理家族回忆"].waitForExistence(timeout: 2))
        attachScreenshot(named: "Portrait - Timeline after rotation")
    }
}
