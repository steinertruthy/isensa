import Foundation
import iSensaCore
@testable import iSensaDesign
@testable import iSensaFeatures
import iSensaInsights
import iSensaMonitoring
import Testing

@Suite("Typeset metrics")
struct MetricTextTests {
    @Test(arguments: [
        ("13,07 GB", "13,07", "GB"), ("48 °C", "48", "°C"), ("7%", "7", "%"), ("7 %", "7", "%"),
        ("2.401 Mbps", "2.401", "Mbps"), ("−3 dBm", "−3", "dBm"), ("1.234,5 W", "1.234,5", "W"),
        ("Normal", "Normal", ""), ("4 hrs", "4", "hrs")
    ])
    func splitsNumberFromUnit(text: String, number: String, unit: String) {
        let parts = MetricText.split(text)
        #expect(parts.number == number)
        #expect(parts.unit == unit)
    }
}

@Suite("Motion")
struct MotionTests {
    @Test func reduceMotionLowersFullButNeverRaisesOff() {
        #expect(Motion.effective(.full, reduceMotion: false) == .full)
        #expect(Motion.effective(.full, reduceMotion: true) == .reduced)
        #expect(Motion.effective(.off, reduceMotion: true) == .off)
        #expect(Motion.resolve(Motion.standard, preference: .off, reduceMotion: false) == nil)
    }

    @Test func utilizationScaleKeepsZeroAndHeadroom() {
        #expect(SeriesSparkline.utilizationRange([0.05, 0.1]) == 0...0.25)
        #expect(SeriesSparkline.utilizationRange([0.4, 0.6]) == 0...0.75)
        #expect(SeriesSparkline.utilizationRange([0.95]) == 0...1)
    }
}

@MainActor
@Suite("Overview model")
struct DashboardModelTests {
    private let profile = DemoProfile.laptop

    @Test func hiddenCellsAndEmptyGroupsDisappear() {
        let store = MetricsStore(profile: profile, staticCapabilities: [.battery: .unavailable, .fans: .unavailable])
        store.handle(.fragment(CPUSnapshot(timestamp: Date(), totalUsage: 0.2, userUsage: 0.1, systemUsage: 0.1, cores: [], loadAverage: [])))
        store.handle(.fragment(GPUSnapshot(
            timestamp: Date(), name: "GPU", coreCount: nil, deviceUtilization: 0.1,
            rendererUtilization: nil, tilerUtilization: nil, memoryInUse: nil, provenance: .system(api: "test")
        )))
        let all = DashboardModel.groups(store: store, formatter: MetricFormatter(), hidden: [])
        #expect(all.map(\.id) == ["performance"])
        #expect(all.first?.cells.map(\.kind) == [.cpu, .gpu])
        let hidden = DashboardModel.groups(store: store, formatter: MetricFormatter(), hidden: [.gpu])
        #expect(hidden.first?.cells.map(\.kind) == [.cpu])
        #expect(DashboardModel.groups(store: store, formatter: MetricFormatter(), hidden: [.cpu, .gpu]).isEmpty)
    }
}

@MainActor
@Suite("Settings persistence")
struct SettingsPersistenceTests {
    private func defaults() -> UserDefaults {
        let suite = "isensa.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func languageWritesPerAppLanguageAndNeedsRelaunch() {
        let suite = "isensa.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(!settings.needsRelaunchForLanguage)
        settings.language = .japanese
        #expect(defaults.persistentDomain(forName: suite)?["AppleLanguages"] as? [String] == ["ja"])
        #expect(settings.needsRelaunchForLanguage)
        settings.language = .system
        #expect(defaults.persistentDomain(forName: suite)?["AppleLanguages"] == nil, "System language removes the per-app override")
        #expect(!settings.needsRelaunchForLanguage)
    }

    @Test func alertsAndHistoryPersist() {
        let defaults = defaults()
        let settings = AppSettings(defaults: defaults)
        settings.alerts.isEnabled = true
        settings.alerts.highTemperature.threshold = 88
        settings.historyRetention = .quarter
        settings.hiddenDashboardCells = [.network]
        settings.motion = .reduced
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.alerts.isEnabled)
        #expect(reloaded.alerts.highTemperature.threshold == 88)
        #expect(reloaded.historyRetention == .quarter)
        #expect(reloaded.hiddenDashboardCells == [.network])
        #expect(reloaded.motion == .reduced)
    }

    @Test func resetRestoresDefaultsButKeepsOnboarding() {
        let settings = AppSettings(defaults: defaults())
        settings.hasCompletedOnboarding = true
        settings.soundsEnabled = false
        settings.alerts.isEnabled = true
        settings.resetToDefaults()
        #expect(settings.soundsEnabled)
        #expect(!settings.alerts.isEnabled)
        #expect(settings.hasCompletedOnboarding)
    }

    @Test func everyLanguageNamesItself() {
        #expect(AppLanguage.japanese.nativeName == "日本語")
        #expect(AppLanguage.german.nativeName == "Deutsch")
        #expect(AppLanguage.translated.count == 10)
    }
}

@MainActor
private final class RecordingDelivery: NotificationDelivering {
    var delivered: [(title: String, identifier: String)] = []
    func authorization() async -> NotificationAuthorization { .authorized }
    func requestAuthorization() async -> Bool { true }
    func deliver(title: String, body: String, identifier: String) { delivered.append((title, identifier)) }
}

@MainActor
@Suite("Alert coordinator")
struct AlertCoordinatorTests {
    @Test func deliversLogsAndGivesFeedbackOnce() {
        let suite = "isensa.tests.\(UUID().uuidString)"
        let settings = AppSettings(defaults: UserDefaults(suiteName: suite)!)
        settings.alerts.isEnabled = true
        let store = MetricsStore(profile: DemoProfile.laptop)
        let delivery = RecordingDelivery()
        var logged: [AlertKind] = []
        var feedbackEvents = 0
        let coordinator = AlertCoordinator(
            store: store, settings: settings, delivery: delivery, feedback: Feedback { _ in feedbackEvents += 1 }
        ) { logged.append($0.kind) }
        store.handle(.fragment(BatterySnapshot(
            timestamp: Date(), charge: 0.1, state: .discharging, isExternalPowerConnected: false, cycleCount: nil,
            designCapacity: nil, nominalCapacity: nil, rawMaxCapacity: nil, remainingCapacity: nil, voltage: nil,
            amperage: nil, temperature: nil, timeToEmpty: nil, timeToFull: nil, systemCondition: nil, adapter: nil
        )))
        #expect(coordinator.evaluate().map(\.kind) == [.lowBattery])
        #expect(coordinator.evaluate().isEmpty, "Already active")
        #expect(delivery.delivered.map(\.identifier) == ["lowBattery"])
        #expect(logged == [.lowBattery])
        #expect(feedbackEvents == 1)
    }
}

enum DemoProfile {
    static let laptop = HardwareProfile(
        modelIdentifier: "Test", marketingName: nil, computerName: nil, chipName: "Test", chipFamily: .unknown,
        architecture: .arm64, cpu: CPUTopology(physicalCores: 2, logicalCores: 2, performanceCores: 1, efficiencyCores: 1),
        gpuCoreCount: nil, physicalMemory: 16 << 30, operatingSystem: "", hasBattery: true, fanCount: 0
    )
}
