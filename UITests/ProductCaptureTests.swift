import AppKit
import XCTest

/// Captures real screenshots of iSensa running on this Mac, with its real sensors, for the website. It runs only when asked (`scripts/capture-media.sh` sets
/// `ISENSA_CAPTURE=1`), never as part of the regular suite. The computer name is hidden and the
/// greeting does not use the person's name.
@MainActor
final class ProductCaptureTests: XCTestCase {

    override func setUpWithError() throws {
        guard ProcessInfo.processInfo.environment["ISENSA_CAPTURE"] == "1" else {
            throw XCTSkip("Set ISENSA_CAPTURE=1 to capture product media")
        }
        continueAfterFailure = true
    }

    func testCaptureScreens() throws {
        for appearance in ["dark", "light"] {
            let app = launch(appearance: appearance)
            // Time for the person running the capture to answer any macOS permission prompt first.
            if appearance == "dark" { pause(25) }
            for destination in ["overview", "cpu", "gpu", "memory", "battery", "thermals", "fans", "storage", "network", "sensors", "history"] {
                guard open(app, "sidebar.\(destination)") else { continue }
                pause(destination == "overview" ? 8 : 3)
                save(app.windows.firstMatch.screenshot(), "\(appearance)-\(destination)")
            }
            if open(app, "sidebar.settings") {
                for pane in ["general", "appearance", "menuBar", "notifications"] where open(app, "settings.\(pane)") {
                    pause(1.5)
                    save(app.windows.firstMatch.screenshot(), "\(appearance)-settings-\(pane)")
                }
            }
            app.terminate()
            capturePopover(appearance: appearance)
        }
    }

    // MARK: - Helpers

    private func launch(appearance: String, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1512, height: 982)
        let size = CGSize(width: min(1320, screen.width - 80), height: min(860, screen.height - 100))
        let origin = CGPoint(x: ((screen.width - size.width) / 2).rounded(), y: ((screen.height - size.height) / 2).rounded())
        let frame = "\(Int(origin.x)) \(Int(origin.y)) \(Int(size.width)) \(Int(size.height)) 0 0 \(Int(screen.width)) \(Int(screen.height))"
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-hidesDockIcon", "NO", "-opensWindowAtLaunch", "YES",
            "-hasCompletedOnboarding", "YES", "-iSensaDisableUpdateCheck", "YES", "-hidesComputerName", "YES", "-greetingUsesName", "NO",
            // Technical details stay closed: the Network screen lists this Mac's IP addresses there.
            "-showsTechnicalDetails", "NO", "-temperatureUnit", "celsius",
            "-appearance", appearance, "-sidebarVisible", "YES", "-NSWindow Frame iSensaMainWindow", frame
        ] + extra
        app.launch()
        app.activate()
        _ = app.descendants(matching: .any)["sidebar.overview"].waitForExistence(timeout: 15)
        return app
    }

    private func capturePopover(appearance: String) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-hidesDockIcon", "YES", "-opensWindowAtLaunch", "NO",
            "-hasCompletedOnboarding", "YES", "-iSensaDisableUpdateCheck", "YES", "-hidesComputerName", "YES", "-temperatureUnit", "celsius", "-appearance", appearance
        ]
        app.launch()
        let item = app.statusItems.firstMatch
        guard item.waitForExistence(timeout: 10) else { return }
        pause(4)
        save(item.screenshot(), "\(appearance)-statusitem")
        item.click()
        let popover = app.descendants(matching: .any)["menubar.popover"]
        if popover.waitForExistence(timeout: 5) {
            pause(3)
            save(popover.screenshot(), "\(appearance)-popover")
        }
        app.terminate()
    }

    @discardableResult
    private func open(_ app: XCUIApplication, _ identifier: String) -> Bool {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        guard element.waitForExistence(timeout: 5), element.isHittable else { return false }
        element.click()
        return true
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    /// The test runner is sandboxed, so media leave as attachments (exported from the result bundle).
    private func save(_ screenshot: XCUIScreenshot, _ name: String) {
        let attachment = XCTAttachment(data: screenshot.pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = "\(name).png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
