import AppKit
import SensaFeatures
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let environment: AppEnvironment
    private var window: NSWindow?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let root = SettingsView(launchAtLogin: environment.launchAtLogin)
            .environment(environment.store)
            .environment(environment.settings)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.title = String(localized: "Settings")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
