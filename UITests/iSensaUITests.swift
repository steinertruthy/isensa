import XCTest

/// UI tests run against clearly-labelled demo providers (`-iSensaDemoMode`), so they are
/// deterministic and never depend on the physical sensors of the machine running them.
@MainActor
final class iSensaUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ variant: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-iSensaDemoMode", variant, "-AppleLanguages", "(en)", "-hidesDockIcon", "NO",
            "-opensWindowAtLaunch", "YES", "-hasCompletedOnboarding", "YES", "-iSensaDisableUpdateCheck", "YES"
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
        let toggle = app.buttons["toolbar.sidebar"].firstMatch // CI runners may leave a second window open.
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

    func testEverySettingsPaneOpensInTheMainWindow() {
        let app = launch("laptopWithFans")
        let settingsRow = app.buttons["sidebar.settings"]
        XCTAssertTrue(settingsRow.waitForExistence(timeout: 10))
        settingsRow.click()
        for pane in ["general", "appearance", "sounds", "overview", "menuBar", "monitoring", "sensors", "battery", "fans",
                     "notifications", "history", "privacy", "advanced", "about"] {
            let row = app.descendants(matching: .any)["settings.\(pane)"].firstMatch
            guard row.waitForExistence(timeout: 2) else { continue } // Panes follow the Mac's capabilities.
            row.click()
            RunLoop.current.run(until: Date().addingTimeInterval(1.5))
            XCTAssertEqual(app.state, .runningForeground, "iSensa stopped after opening \(pane)")
        }
    }

    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    func testFanControlInstallsHelperAndTakesControl() {
        // Demo fan service: no password prompt, no hardware writes.
        let app = launch("laptopWithFans", extraArguments: ["-iSensaInitialDestination", "fans", "-fanMode", "\"\""])
        let install = app.buttons["fans.install"]
        XCTAssertTrue(install.waitForExistence(timeout: 10))
        install.click()
        let mode = app.descendants(matching: .any)["fans.mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.radioButtons["Fixed speed"].click()
        let status = app.descendants(matching: .any)["fans.status"]
        XCTAssertTrue(app.sliders["fans.speed"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(status, labelContaining: "iSensa is controlling the fans"), "Status: \(status.debugDescription)")
        mode.radioButtons["Curve"].click()
        let preset = app.descendants(matching: .any)["fans.preset"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.radioButtons["Custom"].click()
        XCTAssertTrue(app.checkBoxes["fans.custom.macos"].waitForExistence(timeout: 5), "Custom curve controls appear")
        XCTAssertTrue(app.descendants(matching: .any)["fans.curve"].exists)
        mode.radioButtons["Automatic"].click()
        XCTAssertTrue(waitFor(status, labelContaining: "macOS is controlling the fans"), "Status: \(status.debugDescription)")
    }

    private func waitFor(_ element: XCUIElement, labelContaining text: String, timeout: TimeInterval = 8) -> Bool {
        // Static text exposes its string as the value; other elements as the label.
        let predicate = NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout) == .completed
    }

    func testOnboardingWalksThroughAndOpensiSensa() {
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
        let app = launch("fanlessLaptop", extraArguments: ["-iSensaSettingsPane", "notifications"])
        XCTAssertTrue(app.descendants(matching: .any)["settings.notifications.enabled"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["settings.battery"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["settings.fans"].exists, "A fanless Mac has no Fans pane")
    }

    func testStorageExplainsSpaceEjectsAndTestsSpeed() {
        let app = launch("laptopWithFans", extraArguments: ["-iSensaInitialDestination", "storage"])
        XCTAssertTrue(app.descendants(matching: .any)["storage.space"].waitForExistence(timeout: 10), "Used, purgeable and free")
        attachScreenshot(app, "storage-top")
        // The screen is lazy: rows exist once scrolled into view.
        let writer = app.staticTexts.matching(NSPredicate(format: "value BEGINSWITH %@", "Demo Editor: writing")).firstMatch
        scroll(app, to: writer)
        attachScreenshot(app, "storage-activity")
        let performance = app.descendants(matching: .any)["storage.performance"]
        scroll(app, to: performance)
        attachScreenshot(app, "storage-volumes")

        // Disk images can be ejected; the demo eject succeeds without touching anything.
        let image = app.buttons["Eject Demo Installer"]
        scroll(app, to: image)
        image.click()
        XCTAssertTrue(waitUntilGone(image), "An ejected image leaves the list")

        attachScreenshot(app, "storage-images")
        scroll(app, to: app.descendants(matching: .any)["storage.container"])
        let start = app.buttons["storage.speed.start"]
        scroll(app, to: start)
        start.click()
        XCTAssertTrue(app.descendants(matching: .any)["storage.speed.result"].waitForExistence(timeout: 10))
        attachScreenshot(app, "storage-bottom")
    }

    func testFreeUpSpaceReviewsMovesToTrashAndUndoes() {
        let app = launch("laptopWithFans", extraArguments: ["-iSensaInitialDestination", "cleanup"])
        let analyze = app.buttons["space.analyze"]
        XCTAssertTrue(analyze.waitForExistence(timeout: 10))
        analyze.click()
        let review = app.buttons["space.suggestion.installers"]
        XCTAssertTrue(review.waitForExistence(timeout: 10), "Suggestions appear after the analysis")
        attachScreenshot(app, "space-suggestions")
        scroll(app, to: review)
        review.click()
        let confirm = app.buttons["space.review.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Nothing moves before the review")
        confirm.click()
        let undo = app.buttons["space.undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["space.suggestion.installers"].exists, "The installer is gone from the suggestions")
        undo.click()
        XCTAssertTrue(waitUntilGone(undo))

        app.descendants(matching: .any)["space.tabs"].radioButtons["Apps"].click()
        XCTAssertTrue(app.staticTexts["Demo Game"].waitForExistence(timeout: 5))
        attachScreenshot(app, "space-apps")
    }

    private func scroll(_ app: XCUIApplication, to element: XCUIElement) {
        // Scroll the screen's content, not the sidebar.
        let content = app.scrollViews["screen.scroll"]
        let bottom = app.windows.firstMatch.frame.maxY - 40
        // Fully on screen, not just peeking in at the bottom edge.
        for _ in 0..<20 where !(element.exists && element.isHittable && element.frame.maxY < bottom) {
            content.scroll(byDeltaX: 0, deltaY: -250)
        }
        XCTAssertTrue(element.isHittable, "Could not scroll to \(element)")
    }

    private func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testHistoryScreenExplainsEmptyState() {
        let app = launch("laptopWithFans", extraArguments: ["-iSensaInitialDestination", "history"])
        let header = app.descendants(matching: .any)["screen.header"]
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        XCTAssertTrue(header.label.hasPrefix("History"))
        XCTAssertTrue(app.staticTexts["No history yet"].waitForExistence(timeout: 10))
    }
}
