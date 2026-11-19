import AppKit

// AppKit lifecycle: Sensa is a menu-bar-first utility, so windows, menus and the
// status item are managed explicitly. SwiftUI renders all content.
MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    withExtendedLifetime(delegate) {
        application.run()
    }
}
