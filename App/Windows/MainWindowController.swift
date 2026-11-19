import AppKit
import SensaFeatures
import SwiftUI

/// Owns the main window. Reports visibility changes so sampling adapts (occluded = slower).
@MainActor
final class MainWindowController: NSObject, NSWindowDelegate {
    private let environment: AppEnvironment
    private let services: SensaServices
    private let onVisibilityChange: () -> Void
    private var window: NSWindow?

    init(environment: AppEnvironment, services: SensaServices, onVisibilityChange: @escaping () -> Void) {
        self.environment = environment
        self.services = services
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
        let root = RootView()
            .environment(environment.navigation)
            .sensaEnvironment(store: environment.store, settings: environment.settings, feedback: environment.feedback.feedback, services: services)
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
