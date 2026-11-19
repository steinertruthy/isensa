import AppKit
import iSensaFeatures
import SwiftUI

/// Status item drawn by `StatusItemRenderer` (AppKit, template image), plus a native
/// popover fed from cached state.
@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
    private let environment: AppEnvironment
    private let actions: MenuBarActions
    private let services: iSensaServices
    private let onVisibilityChange: () -> Void
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var renderScheduled = false
    private var lastModel: MenuBarLabelModel?

    init(environment: AppEnvironment, actions: MenuBarActions, services: iSensaServices, onVisibilityChange: @escaping () -> Void) {
        self.environment = environment
        self.services = services
        self.actions = actions
        self.onVisibilityChange = onVisibilityChange
    }

    var isPopoverShown: Bool { popover.isShown }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        item.button?.imagePosition = .imageOnly
        item.button?.setAccessibilityLabel("iSensa")
        statusItem = item

        var popoverActions = actions
        let close = { [weak self] in self?.popover.performClose(nil) }
        popoverActions.openMainWindow = { [actions] in close(); actions.openMainWindow() }
        popoverActions.openSettings = { [actions] in close(); actions.openSettings() }
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        let controller = NSHostingController(
            rootView: MenuBarPopover(actions: popoverActions)
                .iSensaEnvironment(store: environment.store, settings: environment.settings, feedback: environment.feedback.feedback, services: services)
        )
        // The popover follows the SwiftUI content's size, so it opens at its final height instead of
        // growing after it is shown (which pushes it above the menu bar).
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        renderLabel()
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem?.button, !popover.isShown else { return }
        if let view = popover.contentViewController?.view {
            view.layoutSubtreeIfNeeded()
            popover.contentSize = view.fittingSize
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidShow(_ notification: Notification) { onVisibilityChange() }
    func popoverDidClose(_ notification: Notification) { onVisibilityChange() }

    /// Re-arms observation and redraws only when the label's content actually changed;
    /// bursts of updates are coalesced into one render per run-loop turn.
    private func renderLabel() {
        renderScheduled = false
        let model = withObservationTracking {
            MenuBarLabelModel.make(store: environment.store, settings: environment.settings)
        } onChange: { [weak self] in
            Task { @MainActor in self?.scheduleRender() }
        }
        guard model != lastModel || statusItem?.button?.image == nil else { return }
        lastModel = model
        statusItem?.button?.image = StatusItemRenderer.image(for: model)
        statusItem?.button?.setAccessibilityValue(model.items.map(\.text).joined(separator: ", "))
    }

    private func scheduleRender() {
        guard !renderScheduled else { return }
        renderScheduled = true
        DispatchQueue.main.async { [weak self] in self?.renderLabel() }
    }
}
