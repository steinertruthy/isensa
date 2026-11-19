import Foundation
import Observation
import SensaDesign
import SensaInsights

public enum AppearancePreference: String, CaseIterable, Codable, Sendable {
    case system, light, dark
}

/// Menu bar indicators the user can show, order and toggle.
public enum MenuBarIndicator: String, CaseIterable, Codable, Sendable, Identifiable {
    case cpuUsage, cpuTemperature, gpuUsage, gpuTemperature, memoryUsed, memoryPressure, battery, power, fans, network

    public var id: String { rawValue }
}

/// How indicators share the menu bar.
public enum MenuBarLayout: String, CaseIterable, Codable, Sendable {
    /// One row: icon + value side by side.
    case inline
    /// Two small rows per column — about half the width, for crowded menu bars.
    case stacked
}

public struct MenuBarItemConfiguration: Codable, Hashable, Sendable, Identifiable {
    public var indicator: MenuBarIndicator
    public var isEnabled: Bool
    public var showsSparkline: Bool

    public var id: MenuBarIndicator { indicator }

    public init(indicator: MenuBarIndicator, isEnabled: Bool, showsSparkline: Bool = false) {
        self.indicator = indicator
        self.isEnabled = isEnabled
        self.showsSparkline = showsSparkline
    }

    public static let defaults: [MenuBarItemConfiguration] = MenuBarIndicator.allCases.map {
        MenuBarItemConfiguration(indicator: $0, isEnabled: $0 == .cpuUsage || $0 == .cpuTemperature)
    }
}

/// How fan speed is shown: absolute RPM, or position within the fan's supported range.
public enum FanSpeedDisplay: String, CaseIterable, Codable, Sendable {
    case rpm, percentOfRange
}

/// History retention choices, in days.
public enum HistoryRetention: Int, CaseIterable, Codable, Sendable {
    case day = 1, week = 7, month = 30, quarter = 90
}

/// User preferences, persisted in `UserDefaults`. Observable so every screen updates live.
@MainActor
@Observable
public final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults

    // Appearance and personalization
    public var appearance: AppearancePreference { didSet { save(appearance.rawValue, .appearance) } }
    public var motion: MotionPreference { didSet { save(motion.rawValue, .motion) } }
    public var greetingUsesName: Bool { didSet { save(greetingUsesName, .greetingUsesName) } }
    /// Interface language. Applied through macOS' per-app `AppleLanguages`; takes effect after relaunch.
    public var language: AppLanguage { didSet { applyLanguage() } }
    /// Language the running process was launched with.
    @ObservationIgnored public let launchLanguage: AppLanguage
    public var showsTechnicalDetails: Bool { didSet { save(showsTechnicalDetails, .showsTechnicalDetails) } }
    public var hiddenDashboardCells: Set<DashboardCellKind> { didSet { saveJSON(hiddenDashboardCells, .hiddenDashboardCells) } }
    // Sounds
    public var soundsEnabled: Bool { didSet { save(soundsEnabled, .soundsEnabled) } }
    public var soundVolume: Double { didSet { save(soundVolume, .soundVolume) } }
    public var hapticsEnabled: Bool { didSet { save(hapticsEnabled, .hapticsEnabled) } }
    // Units and sensors
    public var temperatureUnit: TemperatureUnitPreference { didSet { save(temperatureUnit.rawValue, .temperatureUnit) } }
    public var showsUnknownSensors: Bool { didSet { save(showsUnknownSensors, .showsUnknownSensors) } }
    public var fanSpeedDisplay: FanSpeedDisplay { didSet { save(fanSpeedDisplay.rawValue, .fanSpeedDisplay) } }
    public var favoriteSensors: Set<String> { didSet { saveJSON(favoriteSensors, .favoriteSensors) } }
    public var sensorNicknames: [String: String] { didSet { saveJSON(sensorNicknames, .sensorNicknames) } }
    // Monitoring and performance
    /// Interactive refresh interval in seconds.
    public var refreshInterval: Double { didSet { save(refreshInterval, .refreshInterval) } }
    /// Refresh interval in seconds while only the menu bar is visible.
    public var backgroundRefreshInterval: Double { didSet { save(backgroundRefreshInterval, .backgroundRefreshInterval) } }
    /// Sample less often on battery power.
    public var savesEnergyOnBattery: Bool { didSet { save(savesEnergyOnBattery, .savesEnergyOnBattery) } }
    // Menu bar
    public var menuBarItems: [MenuBarItemConfiguration] { didSet { saveJSON(menuBarItems, .menuBarItems) } }
    public var menuBarShowsIcons: Bool { didSet { save(menuBarShowsIcons, .menuBarShowsIcons) } }
    public var menuBarLayout: MenuBarLayout { didSet { save(menuBarLayout.rawValue, .menuBarLayout) } }
    /// Decimal places for percentages, temperatures and power in the menu bar (0 or 1).
    public var menuBarDecimals: Int { didSet { save(menuBarDecimals, .menuBarDecimals) } }
    // Startup
    public var hidesDockIcon: Bool { didSet { save(hidesDockIcon, .hidesDockIcon) } }
    public var opensWindowAtLaunch: Bool { didSet { save(opensWindowAtLaunch, .opensWindowAtLaunch) } }
    public var hasCompletedOnboarding: Bool { didSet { save(hasCompletedOnboarding, .hasCompletedOnboarding) } }
    // Alerts and history
    public var alerts: AlertConfiguration { didSet { saveJSON(alerts, .alerts) } }
    public var historyEnabled: Bool { didSet { save(historyEnabled, .historyEnabled) } }
    public var historyRetention: HistoryRetention { didSet { save(historyRetention.rawValue, .historyRetention) } }

    private enum Key: String {
        case appearance, motion, greetingUsesName, showsTechnicalDetails, hiddenDashboardCells, language
        case soundsEnabled, soundVolume, hapticsEnabled
        case temperatureUnit, showsUnknownSensors, fanSpeedDisplay, favoriteSensors, sensorNicknames
        case refreshInterval, backgroundRefreshInterval, savesEnergyOnBattery
        case menuBarItems, menuBarShowsIcons, menuBarLayout, menuBarDecimals
        case hidesDockIcon, opensWindowAtLaunch, hasCompletedOnboarding
        case alerts, historyEnabled, historyRetention
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func bool(_ key: Key, _ fallback: Bool) -> Bool {
            // `bool(forKey:)` also parses "YES"/"NO" strings from launch arguments.
            defaults.object(forKey: key.rawValue) == nil ? fallback : defaults.bool(forKey: key.rawValue)
        }
        func double(_ key: Key, _ fallback: Double) -> Double {
            let value = defaults.double(forKey: key.rawValue)
            return value > 0 ? value : fallback
        }
        func string<T: RawRepresentable>(_ key: Key, _ fallback: T) -> T where T.RawValue == String {
            defaults.string(forKey: key.rawValue).flatMap { T(rawValue: $0) } ?? fallback
        }

        appearance = string(.appearance, .system)
        motion = string(.motion, .full)
        greetingUsesName = bool(.greetingUsesName, false)
        let savedLanguage: AppLanguage = string(.language, .system)
        language = savedLanguage
        launchLanguage = savedLanguage
        showsTechnicalDetails = bool(.showsTechnicalDetails, false)
        hiddenDashboardCells = Self.loadJSON(defaults, .hiddenDashboardCells) ?? []
        soundsEnabled = bool(.soundsEnabled, true)
        soundVolume = min(double(.soundVolume, 0.5), 1)
        hapticsEnabled = bool(.hapticsEnabled, true)
        temperatureUnit = string(.temperatureUnit, Locale.current.measurementSystem == .us ? .fahrenheit : .celsius)
        showsUnknownSensors = bool(.showsUnknownSensors, true)
        fanSpeedDisplay = string(.fanSpeedDisplay, .rpm)
        favoriteSensors = Self.loadJSON(defaults, .favoriteSensors) ?? []
        sensorNicknames = Self.loadJSON(defaults, .sensorNicknames) ?? [:]
        refreshInterval = double(.refreshInterval, 1)
        backgroundRefreshInterval = double(.backgroundRefreshInterval, 3)
        savesEnergyOnBattery = bool(.savesEnergyOnBattery, true)
        menuBarItems = Self.loadJSON(defaults, .menuBarItems).map(Self.reconciled) ?? MenuBarItemConfiguration.defaults
        menuBarShowsIcons = bool(.menuBarShowsIcons, true)
        menuBarLayout = string(.menuBarLayout, .inline)
        menuBarDecimals = min(max(defaults.integer(forKey: Key.menuBarDecimals.rawValue), 0), 1)
        hidesDockIcon = bool(.hidesDockIcon, false)
        opensWindowAtLaunch = bool(.opensWindowAtLaunch, true)
        hasCompletedOnboarding = bool(.hasCompletedOnboarding, false)
        alerts = Self.loadJSON(defaults, .alerts) ?? AlertConfiguration()
        historyEnabled = bool(.historyEnabled, true)
        historyRetention = HistoryRetention(rawValue: defaults.integer(forKey: Key.historyRetention.rawValue)) ?? .month
    }

    public var formatter: MetricFormatter {
        MetricFormatter(temperatureUnit: temperatureUnit)
    }

    public var needsRelaunchForLanguage: Bool { language != launchLanguage }

    private func applyLanguage() {
        save(language.rawValue, .language)
        if language == .system {
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set([language.rawValue], forKey: "AppleLanguages")
        }
    }

    public var enabledMenuBarItems: [MenuBarItemConfiguration] {
        menuBarItems.filter(\.isEnabled)
    }

    /// Restores every preference except onboarding completion and history data.
    public func resetToDefaults() {
        let fresh = AppSettings(defaults: UserDefaults(suiteName: "sensa.defaults.\(UUID().uuidString)") ?? .standard)
        appearance = fresh.appearance
        motion = fresh.motion
        greetingUsesName = fresh.greetingUsesName
        showsTechnicalDetails = fresh.showsTechnicalDetails
        hiddenDashboardCells = fresh.hiddenDashboardCells
        soundsEnabled = fresh.soundsEnabled
        soundVolume = fresh.soundVolume
        hapticsEnabled = fresh.hapticsEnabled
        temperatureUnit = fresh.temperatureUnit
        showsUnknownSensors = fresh.showsUnknownSensors
        fanSpeedDisplay = fresh.fanSpeedDisplay
        favoriteSensors = fresh.favoriteSensors
        sensorNicknames = fresh.sensorNicknames
        refreshInterval = fresh.refreshInterval
        backgroundRefreshInterval = fresh.backgroundRefreshInterval
        savesEnergyOnBattery = fresh.savesEnergyOnBattery
        menuBarItems = fresh.menuBarItems
        menuBarShowsIcons = fresh.menuBarShowsIcons
        menuBarLayout = fresh.menuBarLayout
        menuBarDecimals = fresh.menuBarDecimals
        hidesDockIcon = fresh.hidesDockIcon
        opensWindowAtLaunch = fresh.opensWindowAtLaunch
        alerts = fresh.alerts
        historyEnabled = fresh.historyEnabled
        historyRetention = fresh.historyRetention
    }

    /// Keeps saved order but adds indicators introduced by newer versions.
    static func reconciled(_ saved: [MenuBarItemConfiguration]) -> [MenuBarItemConfiguration] {
        let known = Set(saved.map(\.indicator))
        return saved + MenuBarItemConfiguration.defaults.filter { !known.contains($0.indicator) }
    }

    private func save(_ value: Any, _ key: Key) { defaults.set(value, forKey: key.rawValue) }

    private func saveJSON<T: Encodable>(_ value: T, _ key: Key) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key.rawValue)
    }

    private static func loadJSON<T: Decodable>(_ defaults: UserDefaults, _ key: Key) -> T? {
        defaults.data(forKey: key.rawValue).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
}
