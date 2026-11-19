import AppKit
import SensaFeatures
import SwiftUI

/// Status item whose label is SwiftUI rendered into a template image (so macOS tints
/// it for any menu bar appearance), plus a native popover fed from cached state.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let environment: AppEnvironment
    private let actions: MenuBarActions
    private let onVisibilityChange: () -> Void
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var renderScheduled = false
    /// Last rendered content; `nil` forces a render (e.g. when sparklines are visible).
    private var lastRenderKey: String?

    init(environment: AppEnvironment, actions: MenuBarActions, onVisibilityChange: @escaping () -> Void) {
        self.environment = environment
        self.actions = actions
        self.onVisibilityChange = onVisibilityChange
    }

    var isPopoverShown: Bool { popover.isShown }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        item.button?.imagePosition = .imageOnly
        item.button?.setAccessibilityLabel("Sensa")
        statusItem = item

        var popoverActions = actions
        let close = { [weak self] in self?.popover.performClose(nil) }
        popoverActions.openMainWindow = { [actions] in close(); actions.openMainWindow() }
        popoverActions.openSettings = { [actions] in close(); actions.openSettings() }
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopover(actions: popoverActions)
                .environment(environment.store)
                .environment(environment.settings)
        )
        renderLabel()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverDidShow(_ notification: Notification) { onVisibilityChange() }
    func popoverDidClose(_ notification: Notification) { onVisibilityChange() }

    /// Renders the label and re-arms observation; changes are coalesced into one render per run-loop turn.
    private func renderLabel() {
        renderScheduled = false
        let key = withObservationTracking {
            MenuBarLabel.renderKey(store: environment.store, settings: environment.settings)
        } onChange: { [weak self] in
            Task { @MainActor in self?.scheduleRender() }
        }
        guard key == nil || key != lastRenderKey || statusItem?.button?.image == nil else { return }
        lastRenderKey = key
        statusItem?.button?.image = makeImage()
    }

    private func scheduleRender() {
        guard !renderScheduled else { return }
        renderScheduled = true
        DispatchQueue.main.async { [weak self] in self?.renderLabel() }
    }

    private func makeImage() -> NSImage? {
        let label = MenuBarLabel()
            .environment(environment.store)
            .environment(environment.settings)
            .frame(height: 18)
            .foregroundStyle(.black)
        let renderer = ImageRenderer(content: label)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage
        image?.isTemplate = true
        return image
    }
}
