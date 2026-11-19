import XCTest

/// UI tests run against clearly-labelled demo providers (`-SensaDemoMode`), so they are
/// deterministic and never depend on the physical sensors of the machine running them.
final class SensaUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ variant: String, extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-SensaDemoMode", variant, "-AppleLanguages", "(en)", "-hidesDockIcon", "NO"] + extraArguments
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
        // Menu-bar-only mode: no window at launch, popover opened by the launch flag.
        let app = launch("laptopWithFans", extraArguments: ["-hidesDockIcon", "YES", "-SensaOpenPopover", "YES"])
        let popover = app.descendants(matching: .any)["menubar.popover"]
        XCTAssertTrue(popover.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tile.cpu"].exists, "No main window in menu-bar-only mode")
        app.buttons["menubar.open"].click()
        XCTAssertTrue(app.buttons["tile.cpu"].waitForExistence(timeout: 10))
    }
}
