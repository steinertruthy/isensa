import AppKit
import SensaFeatures
import SensaMonitoring

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let environment = AppEnvironment()
    private lazy var mainWindow = MainWindowController(environment: environment, onVisibilityChange: { [weak self] in self?.updateDemand() })
    private lazy var settingsWindow = SettingsWindowController(environment: environment)
    private lazy var statusItem = StatusItemController(
        environment: environment,
        actions: MenuBarActions(
            openMainWindow: { [weak self] in self?.showMainWindow() },
            openSettings: { [weak self] in self?.showSettings() },
            quit: { NSApp.terminate(nil) }
        ),
        onVisibilityChange: { [weak self] in self?.updateDemand() }
    )
    private var systemEvents: SystemEventsObserver?
    private var isScreenAsleep = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make(target: self)
        statusItem.install()
        observeSettings()
        systemEvents = SystemEventsObserver(
            onSleep: { [weak self] in Task { await self?.environment.engine.suspend() } },
            onWake: { [weak self] in Task { await self?.environment.engine.resume() } },
            onScreensSleepChange: { [weak self] asleep in
                self?.isScreenAsleep = asleep
                self?.updateDemand()
            },
            onPowerSourceChange: { [weak self] onBattery in
                Task { await self?.environment.engine.setOnBattery(onBattery) }
            }
        )
        Task {
            await environment.engine.setPolicy(environment.samplingPolicy())
            await environment.engine.start()
        }
        if !environment.settings.hidesDockIcon { showMainWindow() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    /// Closing the window keeps Sensa running in the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Actions

    @objc func showMainWindow() {
        mainWindow.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        settingsWindow.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Demand & settings

    private func updateDemand() {
        let demand: Demand = if isScreenAsleep {
            .idle
        } else if mainWindow.isVisible || statusItem.isPopoverShown {
            .interactive
        } else {
            .background
        }
        Task { await environment.engine.setDemand(demand) }
    }

    /// Re-applies preferences whenever an observed setting changes.
    private func observeSettings() {
        withObservationTracking {
            applySettings()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeSettings() }
        }
    }

    private func applySettings() {
        let settings = environment.settings
        NSApp.appearance = switch settings.appearance {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
        let policy: NSApplication.ActivationPolicy = settings.hidesDockIcon ? .accessory : .regular
        if NSApp.activationPolicy() != policy { NSApp.setActivationPolicy(policy) }
        let sampling = environment.samplingPolicy()
        Task { await environment.engine.setPolicy(sampling) }
    }
}
