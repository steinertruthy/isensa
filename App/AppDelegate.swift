import AppKit
import iSensaCore
import iSensaFeatures
import iSensaMonitoring

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let environment = AppEnvironment()
    private lazy var services = environment.services(actions: AppActions(
        openMainWindow: { [weak self] in self?.showHistory() },
        openSettings: { [weak self] in self?.showSettings() },
        relaunch: { [weak self] in self?.relaunch() },
        showOnboarding: { [weak self] in self?.showOnboarding() },
        revealDataFolder: { Self.revealDataFolder() }
    ))
    private lazy var mainWindow = MainWindowController(
        environment: environment, services: services, onVisibilityChange: { [weak self] in self?.updateDemand() }
    )
    private lazy var settingsWindow = SettingsWindowController(environment: environment, services: services)
    private lazy var onboardingWindow = OnboardingWindowController(environment: environment, services: services)
    private lazy var statusItem = StatusItemController(
        environment: environment,
        actions: MenuBarActions(
            openMainWindow: { [weak self] in self?.showMainWindow() },
            openSettings: { [weak self] in self?.showSettings() },
            quit: { NSApp.terminate(nil) }
        ),
        services: services,
        onVisibilityChange: { [weak self] in self?.updateDemand() }
    )
    private var systemEvents: SystemEventsObserver?
    private var isScreenAsleep = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make(target: self)
        statusItem.install()
        observeSettings()
        systemEvents = SystemEventsObserver(
            onSleep: { [weak self] in
                Task {
                    // Fans go back to macOS before sleeping; the helper's lease would expire anyway.
                    await self?.environment.fanControl?.suspend()
                    await self?.environment.engine.suspend()
                }
            },
            onWake: { [weak self] in
                Task { await self?.environment.engine.resume() }
                self?.environment.fanControl?.resume()
            },
            onScreensSleepChange: { [weak self] asleep in
                self?.isScreenAsleep = asleep
                self?.updateDemand()
            },
            onPowerSourceChange: { [weak self] onBattery in
                Task { await self?.environment.engine.setOnBattery(onBattery) }
            }
        )
        if !environment.settings.hasCompletedOnboarding && !UserDefaults.standard.bool(forKey: "iSensaSkipOnboarding") {
            showOnboarding()
        } else if environment.settings.opensWindowAtLaunch && !environment.settings.hidesDockIcon {
            showMainWindow()
        }
        // Decide the initial demand before sampling starts: launching straight into the
        // menu bar must not sample at window rates until something becomes visible.
        let initialDemand = currentDemand()
        Task {
            await environment.engine.setPolicy(environment.samplingPolicy())
            await environment.engine.setDemand(initialDemand)
            await environment.engine.start()
        }
        environment.fanControl?.start()
        environment.updates?.start()
        // `-iSensaOpenPopover YES` opens the popover at launch (UI tests, screenshots).
        if UserDefaults.standard.bool(forKey: "iSensaOpenPopover") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.statusItem.showPopover() }
        }
        // `-iSensaSettingsPane <name>` opens Settings at launch (UI tests, screenshots).
        if UserDefaults.standard.string(forKey: "iSensaSettingsPane") != nil { showSettings() }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    /// Closing the window keeps iSensa running in the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Returns the fans to macOS and gives pending history a moment to reach disk before quitting.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            await environment.fanControl?.suspend()
            await environment.flushHistory()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    // MARK: - App actions

    private func showHistory() {
        environment.navigation.selection = .history
        showMainWindow()
    }

    private func showOnboarding() {
        onboardingWindow.show { [weak self] in
            guard let self, !environment.settings.hidesDockIcon else { return }
            showMainWindow()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Restarts iSensa so a new interface language takes effect.
    private func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        let url = Bundle.main.bundleURL
        Task {
            await environment.flushHistory()
            _ = try? await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            NSApp.terminate(nil)
        }
    }

    private static func revealDataFolder() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("iSensa", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }

    // MARK: - Actions

    @objc func showMainWindow() {
        mainWindow.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        settingsWindow.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    /// "Check for Updates…": checks now and answers in a dialog, like other Mac apps.
    @objc func checkForUpdates() {
        guard let updates = environment.updates else { return }
        Task {
            await updates.check()
            let current = updates.currentVersion?.description ?? "–"
            let alert = NSAlert()
            switch updates.status {
            case .available(let update):
                alert.messageText = String(format: String(localized: "iSensa %@ is available"), update.version.description)
                // swiftlint:disable:next line_length
                let advice = String(localized: "You are using version %@. Download the disk image from GitHub and drag iSensa to Applications to replace this one.")
                alert.informativeText = String(format: advice, current)
                alert.addButton(withTitle: String(localized: "Download"))
                alert.addButton(withTitle: String(localized: "Later"))
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(update.pageURL) }
                return
            case .upToDate:
                alert.messageText = String(localized: "iSensa is up to date")
                alert.informativeText = String(format: String(localized: "Version %@ is the latest."), current)
            default:
                alert.alertStyle = .warning
                alert.messageText = String(localized: "Could not check for updates")
                alert.informativeText = String(localized: "GitHub could not be reached. Check your connection and try again.")
            }
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @objc func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Demand & settings

    private func updateDemand() {
        let demand = currentDemand()
        Task { await environment.engine.setDemand(demand) }
    }

    private func currentDemand() -> Demand {
        if isScreenAsleep { return .idle }
        // A window that is ordered in counts as visible even before occlusion is reported.
        return mainWindow.isVisible || statusItem.isPopoverShown ? .interactive : .background
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
