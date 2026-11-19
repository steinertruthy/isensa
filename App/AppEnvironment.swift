import AppKit
import Foundation
import SensaControl
import SensaCore
import SensaDemo
import SensaFeatures
import SensaInsights
import SensaMonitoring
import SensaPersistence
import SensaProviders

/// Composition root: the only place that knows concrete implementations.
@MainActor
final class AppEnvironment {
    let profile: HardwareProfile
    let engine: MonitoringEngine
    let store: MetricsStore
    let settings: AppSettings
    let navigation = AppNavigation()
    let launchAtLogin: LaunchAtLoginControlling
    let feedback: FeedbackPlayer
    let notifications = UserNotificationDelivery()
    let history: HistoryStore?
    let storageServices: StorageServices
    private(set) var alerts: AlertCoordinator?
    /// Present only on Macs with fans.
    let fanControl: FanControlCoordinator?
    private var maintenance: Task<Void, Never>?

    init(arguments: UserDefaults = .standard) {
        settings = AppSettings()
        launchAtLogin = LaunchAtLoginService()
        feedback = FeedbackPlayer(settings: settings)
        // "cleanup" opens Storage › Free Up Space.
        if arguments.string(forKey: "SensaInitialDestination") == "cleanup" {
            navigation.selection = .storage
            navigation.storagePage = .freeUpSpace
        } else if let initial = arguments.string(forKey: "SensaInitialDestination").flatMap(Destination.init) {
            navigation.selection = initial
        }

        // `-SensaDemoMode <variant>` swaps in clearly-labelled demonstration providers
        // (UI tests, screenshots). Production and demo providers are never mixed, and demo
        // data is never written to history.
        let isDemo: Bool
        if let variantName = arguments.string(forKey: "SensaDemoMode") {
            let variant = DemoEnvironment.Variant(rawValue: variantName) ?? .laptopWithFans
            profile = DemoEnvironment.profile(variant)
            engine = MonitoringEngine(providers: DemoEnvironment.providers(for: profile))
            store = MetricsStore(profile: profile, staticCapabilities: DemoEnvironment.staticCapabilities(for: profile), isDemo: true)
            isDemo = true
        } else {
            profile = HardwareDiscovery.discover()
            engine = MonitoringEngine(providers: ProductionProviders.make(for: profile))
            store = MetricsStore(profile: profile, staticCapabilities: ProductionProviders.staticCapabilities(for: profile))
            isDemo = false
        }
        storageServices = isDemo ? Self.demoStorageServices() : Self.storageServices()
        history = isDemo ? nil : try? HistoryStore(url: HistoryStore.defaultURL())
        if profile.fanCount > 0 {
            // Demo mode never touches the helper or the hardware.
            // `-SensaDemoFanHelperInstalled YES` starts demo mode with the demo helper in place (screenshots).
            let service: any FanControlService = isDemo
                ? DemoFanControlService(installed: arguments.bool(forKey: "SensaDemoFanHelperInstalled"))
                : XPCFanControlService()
            fanControl = FanControlCoordinator(service: service, store: store, settings: settings)
        } else {
            fanControl = nil
        }
        store.consume(engine.events)
        startHistory()
        startAlerts()
    }

    private static func storageServices() -> StorageServices {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let applicationFolders = [URL(fileURLWithPath: "/Applications"), home.appendingPathComponent("Applications")]
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        let analysis = SpaceAnalysis(dependencies: .init(
            scanner: DiskUsageScanner(home: home),
            inventory: { sizes in InstalledApps(home: home, knownSizes: sizes) },
            trash: AdministratorTrash(), home: home, applicationFolders: applicationFolders, ownBundle: Bundle.main.bundleURL
        ))
        return StorageServices(speedTester: DiskSpeedTester(), eject: { url in
            try await Task.detached { try NSWorkspace.shared.unmountAndEjectDevice(at: url) }.value
        }, spaceAnalysis: analysis)
    }

    private static func demoStorageServices() -> StorageServices {
        let analysis = SpaceAnalysis(dependencies: .init(
            scanner: DemoDiskUsageScanner(), inventory: { _ in DemoAppInventory() }, trash: DemoTrash(),
            home: DemoSpace.home, applicationFolders: [DemoSpace.applications], ownBundle: Bundle.main.bundleURL
        ))
        return StorageServices(speedTester: DemoDiskSpeedTester(), eject: DemoDiskSpeedTester.eject, spaceAnalysis: analysis)
    }

    func samplingPolicy() -> SamplingPolicy {
        SamplingPolicy(
            interactiveInterval: settings.refreshInterval,
            backgroundInterval: settings.backgroundRefreshInterval,
            batteryMultiplier: settings.savesEnergyOnBattery ? 1.5 : 1
        )
    }

    func services(actions: AppActions) -> SensaServices {
        SensaServices(
            history: history, alerts: alerts, notifications: notifications, launchAtLogin: launchAtLogin,
            fanControl: fanControl, storage: storageServices, actions: actions
        )
    }

    /// Writes pending history before quitting.
    func flushHistory() async {
        try? await history?.flush()
    }

    private func startHistory() {
        guard let history else { return }
        let settings = settings
        store.addReadingObserver { readings in
            guard settings.historyEnabled, !readings.isEmpty else { return }
            Task { try? await history.record(readings) }
        }
        maintenance = Task { [settings] in
            while !Task.isCancelled {
                let days = await MainActor.run { settings.historyRetention.rawValue }
                try? await history.maintain(retentionDays: days)
                try? await Task.sleep(for: .seconds(3_600))
            }
        }
    }

    private func startAlerts() {
        let history = history
        let coordinator = AlertCoordinator(
            store: store, settings: settings, delivery: notifications, feedback: feedback.feedback
        ) { event in
            Task { try? await history?.log(kind: event.kind.rawValue, level: event.level, value: event.value, at: event.date) }
        }
        coordinator.start()
        alerts = coordinator
    }
}
