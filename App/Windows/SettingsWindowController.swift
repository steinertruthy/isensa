import AppKit
import SensaFeatures
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let environment: AppEnvironment
    private let services: SensaServices
    private var window: NSWindow?

    init(environment: AppEnvironment, services: SensaServices) {
        self.environment = environment
        self.services = services
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let root = SettingsView()
            .sensaEnvironment(store: environment.store, settings: environment.settings, feedback: environment.feedback.feedback, services: services)
        let controller = NSHostingController(rootView: root)
        controller.sceneBridgingOptions = [.toolbars, .title]
        let window = NSWindow(contentViewController: controller)
        window.title = String(localized: "Settings")
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 760, height: 560))
        window.setFrameAutosaveName("SensaSettingsWindow")
        window.center()
        return window
    }
}

/// First-run welcome, in its own small window.
@MainActor
final class OnboardingWindowController {
    private let environment: AppEnvironment
    private let services: SensaServices
    private var window: NSWindow?

    init(environment: AppEnvironment, services: SensaServices) {
        self.environment = environment
        self.services = services
    }

    func show(onFinish: @escaping @MainActor () -> Void) {
        let root = OnboardingView { [weak self] in
            self?.window?.close()
            self?.window = nil
            onFinish()
        }
        .sensaEnvironment(store: environment.store, settings: environment.settings, feedback: environment.feedback.feedback, services: services)
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }
}
