import Foundation
import SensaCore
import SensaDemo
import SensaFeatures
import SensaMonitoring
import SensaProviders

/// Composition root: the only place that knows concrete implementations.
@MainActor
final class AppEnvironment {
    let profile: HardwareProfile
    let engine: MonitoringEngine
    let store: MetricsStore
    let settings: AppSettings
    let launchAtLogin: LaunchAtLoginControlling

    init(arguments: UserDefaults = .standard) {
        settings = AppSettings()
        launchAtLogin = LaunchAtLoginService()

        // `-SensaDemoMode <variant>` swaps in clearly-labelled demonstration providers
        // (UI tests, screenshots). Production and demo providers are never mixed.
        if let variantName = arguments.string(forKey: "SensaDemoMode") {
            let variant = DemoEnvironment.Variant(rawValue: variantName) ?? .laptopWithFans
            profile = DemoEnvironment.profile(variant)
            engine = MonitoringEngine(providers: DemoEnvironment.providers(for: profile))
            store = MetricsStore(profile: profile, staticCapabilities: DemoEnvironment.staticCapabilities(for: profile), isDemo: true)
        } else {
            profile = HardwareDiscovery.discover()
            engine = MonitoringEngine(providers: ProductionProviders.make(for: profile))
            store = MetricsStore(profile: profile, staticCapabilities: ProductionProviders.staticCapabilities(for: profile))
        }
        store.consume(engine.events)
    }

    func samplingPolicy() -> SamplingPolicy {
        SamplingPolicy(interactiveInterval: settings.refreshInterval, backgroundInterval: settings.backgroundRefreshInterval)
    }
}
