import AppKit
import XCTest

/// Captures real screenshots of iSensa running on this Mac, with its real sensors, for the website
/// and the product video. It runs only when asked (`scripts/capture-media.sh` sets
/// `ISENSA_CAPTURE=1`), never as part of the regular suite. The computer name is hidden and the
/// greeting does not use the person's name.
@MainActor
final class ProductCaptureTests: XCTestCase {
    private var started = Date()
    private var timeline: [[String: Any]] = []

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

    /// One continuous tour of the real app, recorded by the test runner's screen recording;
    /// the timeline tells the editing script which part of the screen and which seconds to keep.
    func testRecordTour() throws {
        let app = launch(appearance: "dark")
        started = Date()
        let window = app.windows.firstMatch
        mark("window", frame: window.frame)
        let tour: [(String, TimeInterval)] = [
            ("overview", 9), ("cpu", 6), ("gpu", 5), ("thermals", 6), ("battery", 5), ("fans", 5), ("memory", 4), ("history", 6), ("settings", 0)
        ]
        for (destination, seconds) in tour {
            guard open(app, "sidebar.\(destination)") else { continue }
            mark(destination, frame: window.frame)
            if destination == "settings" {
                for pane in ["general", "menuBar", "notifications"] where open(app, "settings.\(pane)") {
                    mark("settings-\(pane)", frame: window.frame)
                    pause(3)
                }
            } else {
                pause(seconds)
            }
        }
        // The menu bar: hide the window, then open the popover from the status item.
        app.typeKey("w", modifierFlags: .command)
        pause(1)
        let item = app.statusItems.firstMatch
        if item.waitForExistence(timeout: 5) {
            item.click()
            let popover = app.descendants(matching: .any)["menubar.popover"]
            if popover.waitForExistence(timeout: 5) {
                mark("popover", frame: popover.frame.union(item.frame))
                pause(7)
            }
        }
        mark("end", frame: .zero)
        writeTimeline()
        app.terminate()
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
            "-hasCompletedOnboarding", "YES", "-hidesComputerName", "YES", "-greetingUsesName", "NO",
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
            "-hasCompletedOnboarding", "YES", "-hidesComputerName", "YES", "-temperatureUnit", "celsius", "-appearance", appearance
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

    private func mark(_ scene: String, frame: CGRect) {
        timeline.append([
            "scene": scene, "t": Date().timeIntervalSince(started), "wall": Date().timeIntervalSince1970,
            "frame": [frame.minX, frame.minY, frame.width, frame.height]
        ])
    }

    private func writeTimeline() {
        let screen = NSScreen.main
        let info: [String: Any] = [
            "scale": screen?.backingScaleFactor ?? 2, "screen": [screen?.frame.width ?? 0, screen?.frame.height ?? 0], "events": timeline
        ]
        if let data = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted]) {
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = "timeline.json"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
