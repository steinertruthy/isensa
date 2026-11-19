import AppKit
import SensaFeatures
import SwiftUI

/// Owns the main window. Reports visibility changes so sampling adapts (occluded = slower).
@MainActor
final class MainWindowController: NSObject, NSWindowDelegate {
    private let environment: AppEnvironment
    private let onVisibilityChange: () -> Void
    private var window: NSWindow?

    init(environment: AppEnvironment, onVisibilityChange: @escaping () -> Void) {
        self.environment = environment
        self.onVisibilityChange = onVisibilityChange
    }

    var isVisible: Bool {
        guard let window else { return false }
        return window.isVisible && window.occlusionState.contains(.visible) && !window.isMiniaturized
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        window.makeKeyAndOrderFront(nil)
        onVisibilityChange()
    }

    private func makeWindow() -> NSWindow {
        // `-SensaInitialDestination <name>` opens a specific screen (UI tests, screenshots).
        let initial = UserDefaults.standard.string(forKey: "SensaInitialDestination").flatMap(Destination.init) ?? .overview
        let root = RootView(initialSelection: initial)
            .environment(environment.store)
            .environment(environment.settings)
        let controller = NSHostingController(rootView: root)
        controller.sceneBridgingOptions = [.toolbars, .title]
        let window = NSWindow(contentViewController: controller)
        window.title = "Sensa"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.setContentSize(NSSize(width: 1_120, height: 760))
        window.center()
        window.setFrameAutosaveName("SensaMainWindow")
        window.delegate = self
        return window
    }

    func windowDidChangeOcclusionState(_ notification: Notification) { onVisibilityChange() }
    func windowDidMiniaturize(_ notification: Notification) { onVisibilityChange() }
    func windowDidDeminiaturize(_ notification: Notification) { onVisibilityChange() }
    func windowWillClose(_ notification: Notification) {
        Task { @MainActor in self.onVisibilityChange() }
    }
}
