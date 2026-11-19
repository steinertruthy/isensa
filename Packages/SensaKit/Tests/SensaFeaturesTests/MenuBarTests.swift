import Foundation
import SensaCore
@testable import SensaFeatures
import SensaMonitoring
import Testing

@MainActor
@Suite("Menu bar label")
struct MenuBarLabelTests {
    private let profile = HardwareProfile(
        modelIdentifier: "Test", marketingName: nil, computerName: nil, chipName: "Test", chipFamily: .unknown,
        architecture: .arm64, cpu: CPUTopology(physicalCores: 2, logicalCores: 2, performanceCores: 1, efficiencyCores: 1),
        gpuCoreCount: nil, physicalMemory: 16 << 30, operatingSystem: "", hasBattery: false, fanCount: 0
    )

    private func settings() -> AppSettings {
        let suite = "sensa.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return AppSettings(defaults: defaults)
    }

    private func cpu(_ usage: Double) -> CPUSnapshot {
        CPUSnapshot(timestamp: Date(), totalUsage: usage, userUsage: usage, systemUsage: 0, cores: [], loadAverage: [])
    }

    @Test func showsOnlyEnabledIndicatorsWithData() {
        let store = MetricsStore(profile: profile)
        let settings = settings()
        store.handle(.fragment(cpu(0.42)))
        let model = MenuBarLabelModel.make(store: store, settings: settings)
        // Defaults: CPU usage + CPU temperature; temperature has no data yet, so it is omitted.
        #expect(model.items.count == 1)
        #expect(model.items.first?.symbol == "cpu")
        #expect(model.items.first?.text.contains("42") == true)
    }

    @Test func respectsIconsLayoutAndSparklineSettings() throws {
        let store = MetricsStore(profile: profile)
        let settings = settings()
        settings.menuBarShowsIcons = false
        settings.menuBarLayout = .stacked
        settings.menuBarItems[0].showsSparkline = true
        for usage in [0.0, 0.5, 1.0] { store.handle(.fragment(cpu(usage))) }
        let model = MenuBarLabelModel.make(store: store, settings: settings)
        let item = try #require(model.items.first)
        #expect(item.symbol == nil)
        #expect(model.layout == .stacked)
        #expect(item.sparkline == [0, 0.5, 1])
    }

    @Test func modelIsEqualWhenNothingVisibleChanges() {
        let store = MetricsStore(profile: profile)
        let settings = settings()
        store.handle(.fragment(cpu(0.42)))
        let first = MenuBarLabelModel.make(store: store, settings: settings)
        store.handle(.fragment(cpu(0.421)))
        #expect(MenuBarLabelModel.make(store: store, settings: settings) == first, "Same rounded text → no re-render")
    }

    @Test func normalisationUsesFixedRangeOrData() {
        #expect(MenuBarLabelModel.normalized([0.25, 0.5], range: 0...1) == [0.25, 0.5])
        #expect(MenuBarLabelModel.normalized([40, 50, 60], range: nil) == [0, 0.5, 1])
        #expect(MenuBarLabelModel.normalized([7, 7], range: nil) == [0.5, 0.5])
    }
}

@MainActor
@Suite("Settings")
struct SettingsTests {
    @Test func persistsAndReloads() {
        let suite = "sensa.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let settings = AppSettings(defaults: defaults)
        settings.menuBarLayout = .stacked
        settings.menuBarDecimals = 1
        settings.backgroundRefreshInterval = 10
        settings.favoriteSensors = ["smc.Tp01"]
        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.menuBarLayout == .stacked)
        #expect(reloaded.menuBarDecimals == 1)
        #expect(reloaded.backgroundRefreshInterval == 10)
        #expect(reloaded.favoriteSensors == ["smc.Tp01"])
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func launchArgumentStringsAreParsed() {
        let suite = "sensa.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set("NO", forKey: "menuBarShowsIcons")
        #expect(!AppSettings(defaults: defaults).menuBarShowsIcons)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func newIndicatorsAreAppendedToSavedOrder() {
        let saved = [MenuBarItemConfiguration(indicator: .network, isEnabled: true)]
        let reconciled = AppSettings.reconciled(saved)
        #expect(reconciled.first?.indicator == .network)
        #expect(Set(reconciled.map(\.indicator)) == Set(MenuBarIndicator.allCases))
    }

    @Test func greetingPeriods() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        func date(_ hour: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: hour))! }
        #expect(DayPeriod(date: date(5), calendar: calendar) == .morning)
        #expect(DayPeriod(date: date(11), calendar: calendar) == .morning)
        #expect(DayPeriod(date: date(12), calendar: calendar) == .afternoon)
        #expect(DayPeriod(date: date(18), calendar: calendar) == .evening)
        #expect(DayPeriod(date: date(2), calendar: calendar) == .evening)
        #expect(Greeting.firstName(fromFullName: "Ana Maria Souza") == "Ana")
    }
}
