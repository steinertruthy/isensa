import XCTest

/// UI tests run against clearly-labelled demo providers (`-SensaDemoMode`), so they are
/// deterministic and never depend on the physical sensors of the machine running them.
@MainActor
final class SensaUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ variant: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-SensaDemoMode", variant, "-AppleLanguages", "(en)", "-hidesDockIcon", "NO",
            "-opensWindowAtLaunch", "YES", "-hasCompletedOnboarding", "YES"
        ] + extraArguments
        app.launch()
        return app
    }

    func testDashboardShowsHealthAndTiles() {
        let app = launch("laptopWithFans")
        XCTAssertTrue(app.descendants(matching: .any)["dashboard.health"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["tile.battery"].exists)
        XCTAssertTrue(app.buttons["tile.fans"].exists)
    }

    func testFanlessLaptopHidesFans() {
        let app = launch("fanlessLaptop")
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["sidebar.fans"].exists)
        XCTAssertFalse(app.buttons["tile.fans"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["sidebar.battery"].exists)
    }

    func testDesktopHidesBattery() {
        let app = launch("desktop")
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["sidebar.battery"].exists)
        XCTAssertFalse(app.buttons["tile.battery"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["sidebar.fans"].exists)
    }

    func testTileNavigatesToDetail() {
        let app = launch("laptopWithFans")
        let tile = app.buttons["tile.memory"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.click()
        let header = app.descendants(matching: .any)["screen.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(header.label.hasPrefix("Memory"), "Unexpected screen: \(header.label)")
    }

    func testMenuBarPopoverOpensMainWindow() {
        // Menu-bar-only mode: no window at launch; the popover opens from the status item, like a person would.
        let app = launch("laptopWithFans", extraArguments: ["-hidesDockIcon", "YES", "-opensWindowAtLaunch", "NO"])
        let item = app.statusItems.firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tile.cpu"].exists, "No main window in menu-bar-only mode")
        item.click()
        let popover = app.descendants(matching: .any)["menubar.popover"]
        XCTAssertTrue(popover.waitForExistence(timeout: 5))
        // The whole popover must be on screen, below the menu bar.
        let open = app.buttons["menubar.open"]
        XCTAssertTrue(open.isHittable, "Open button must be visible: \(open.frame)")
        XCTAssertGreaterThanOrEqual(popover.frame.minY, item.frame.minY, "Popover drawn above the menu bar: \(popover.frame)")
        open.click()
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10))
    }

    func testSidebarCollapsesAndOpensSettings() {
        // No launch argument for `sidebarVisible`: it would shadow the value the toggle saves.
        let app = launch("laptopWithFans")
        let toggle = app.buttons["toolbar.sidebar"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let settingsRow = app.buttons["sidebar.settings"]
        if !settingsRow.waitForExistence(timeout: 2) { toggle.click() } // Left collapsed by an earlier run.
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 5))

        toggle.click()
        XCTAssertTrue(waitUntilGone(app.descendants(matching: .any)["sidebar.cpu"]), "Sidebar should collapse")
        toggle.click()
        XCTAssertTrue(app.descendants(matching: .any)["sidebar.cpu"].waitForExistence(timeout: 5))

        app.typeKey("s", modifierFlags: [.command, .control]) // View › Toggle Sidebar
        XCTAssertTrue(waitUntilGone(app.descendants(matching: .any)["sidebar.cpu"]), "⌃⌘S should collapse the sidebar")
        app.typeKey("s", modifierFlags: [.command, .control])
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 5))

        settingsRow.click()
        XCTAssertTrue(app.descendants(matching: .any)["settings.general"].waitForExistence(timeout: 5))
    }

    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    func testFanControlInstallsHelperAndTakesControl() {
        // Demo fan service: no password prompt, no hardware writes.
        let app = launch("laptopWithFans", extraArguments: ["-SensaInitialDestination", "fans", "-fanMode", "\"\""])
        let install = app.buttons["fans.install"]
        XCTAssertTrue(install.waitForExistence(timeout: 10))
        install.click()
        let mode = app.descendants(matching: .any)["fans.mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.radioButtons["Fixed speed"].click()
        let status = app.descendants(matching: .any)["fans.status"]
        XCTAssertTrue(app.sliders["fans.speed"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(status, labelContaining: "Sensa is controlling the fans"), "Status: \(status.debugDescription)")
        mode.radioButtons["Automatic"].click()
        XCTAssertTrue(waitFor(status, labelContaining: "macOS is controlling the fans"), "Status: \(status.debugDescription)")
    }

    private func waitFor(_ element: XCUIElement, labelContaining text: String, timeout: TimeInterval = 8) -> Bool {
        // Static text exposes its string as the value; other elements as the label.
        let predicate = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout) == .completed
    }

    func testOnboardingWalksThroughAndOpensSensa() {
        let app = launch("laptopWithFans", extraArguments: ["-hasCompletedOnboarding", "NO"])
        let next = app.buttons["onboarding.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        next.click() // Welcome → Your Mac
        XCTAssertTrue(app.staticTexts["Your Mac"].waitForExistence(timeout: 5))
        next.click() // → Menu bar
        next.click() // → Notifications
        XCTAssertTrue(app.staticTexts["Stay informed"].waitForExistence(timeout: 5))
        next.click() // → Ready (notifications skipped)
        XCTAssertTrue(app.staticTexts["You're all set"].waitForExistence(timeout: 5))
        next.click()
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10), "Finishing opens the overview")
    }

    func testSettingsShowsHardwarePanesOnlyWhenPresent() {
        let app = launch("fanlessLaptop", extraArguments: ["-SensaSettingsPane", "notifications"])
        XCTAssertTrue(app.descendants(matching: .any)["settings.notifications.enabled"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["settings.battery"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["settings.fans"].exists, "A fanless Mac has no Fans pane")
    }

    func testHistoryScreenExplainsEmptyState() {
        let app = launch("laptopWithFans", extraArguments: ["-SensaInitialDestination", "history"])
        let header = app.descendants(matching: .any)["screen.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(header.label.hasPrefix("History"))
        XCTAssertTrue(app.staticTexts["No history yet"].waitForExistence(timeout: 10))
    }
}
