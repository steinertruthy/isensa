import Foundation
import Observation

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

/// User preferences, persisted in `UserDefaults`. Observable so every screen updates live.
@MainActor
@Observable
public final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults

    public var appearance: AppearancePreference { didSet { save(appearance.rawValue, .appearance) } }
    public var temperatureUnit: TemperatureUnitPreference { didSet { save(temperatureUnit.rawValue, .temperatureUnit) } }
    /// Interactive refresh interval in seconds.
    public var refreshInterval: Double { didSet { save(refreshInterval, .refreshInterval) } }
    /// Refresh interval in seconds while only the menu bar is visible.
    public var backgroundRefreshInterval: Double { didSet { save(backgroundRefreshInterval, .backgroundRefreshInterval) } }
    public var menuBarShowsIcons: Bool { didSet { save(menuBarShowsIcons, .menuBarShowsIcons) } }
    public var menuBarLayout: MenuBarLayout { didSet { save(menuBarLayout.rawValue, .menuBarLayout) } }
    /// Decimal places for percentages, temperatures and power in the menu bar (0 or 1).
    public var menuBarDecimals: Int { didSet { save(menuBarDecimals, .menuBarDecimals) } }
    public var greetingUsesName: Bool { didSet { save(greetingUsesName, .greetingUsesName) } }
    public var showsTechnicalDetails: Bool { didSet { save(showsTechnicalDetails, .showsTechnicalDetails) } }
    public var hidesDockIcon: Bool { didSet { save(hidesDockIcon, .hidesDockIcon) } }
    public var menuBarItems: [MenuBarItemConfiguration] { didSet { saveJSON(menuBarItems, .menuBarItems) } }
    public var favoriteSensors: Set<String> { didSet { saveJSON(favoriteSensors, .favoriteSensors) } }
    public var sensorNicknames: [String: String] { didSet { saveJSON(sensorNicknames, .sensorNicknames) } }

    private enum Key: String {
        case appearance, temperatureUnit, refreshInterval, greetingUsesName, showsTechnicalDetails
        case backgroundRefreshInterval, menuBarShowsIcons, menuBarLayout, menuBarDecimals
        case hidesDockIcon, menuBarItems, favoriteSensors, sensorNicknames
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Key.appearance.rawValue).flatMap(AppearancePreference.init) ?? .system
        temperatureUnit = defaults.string(forKey: Key.temperatureUnit.rawValue).flatMap(TemperatureUnitPreference.init)
            ?? (Locale.current.measurementSystem == .us ? .fahrenheit : .celsius)
        let interval = defaults.double(forKey: Key.refreshInterval.rawValue)
        refreshInterval = interval > 0 ? interval : 1
        let backgroundInterval = defaults.double(forKey: Key.backgroundRefreshInterval.rawValue)
        backgroundRefreshInterval = backgroundInterval > 0 ? backgroundInterval : 3
        // `bool(forKey:)` also parses "YES"/"NO" strings from launch arguments.
        menuBarShowsIcons = defaults.object(forKey: Key.menuBarShowsIcons.rawValue) == nil || defaults.bool(forKey: Key.menuBarShowsIcons.rawValue)
        menuBarLayout = defaults.string(forKey: Key.menuBarLayout.rawValue).flatMap(MenuBarLayout.init) ?? .inline
        menuBarDecimals = min(max(defaults.integer(forKey: Key.menuBarDecimals.rawValue), 0), 1)
        greetingUsesName = defaults.bool(forKey: Key.greetingUsesName.rawValue)
        showsTechnicalDetails = defaults.bool(forKey: Key.showsTechnicalDetails.rawValue)
        hidesDockIcon = defaults.bool(forKey: Key.hidesDockIcon.rawValue)
        menuBarItems = Self.loadJSON(defaults, .menuBarItems).map(Self.reconciled) ?? MenuBarItemConfiguration.defaults
        favoriteSensors = Self.loadJSON(defaults, .favoriteSensors) ?? []
        sensorNicknames = Self.loadJSON(defaults, .sensorNicknames) ?? [:]
    }

    public var formatter: MetricFormatter {
        MetricFormatter(temperatureUnit: temperatureUnit)
    }

    public var enabledMenuBarItems: [MenuBarItemConfiguration] {
        menuBarItems.filter(\.isEnabled)
    }

    public func resetToDefaults() {
        appearance = .system
        temperatureUnit = Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
        refreshInterval = 1
        backgroundRefreshInterval = 3
        menuBarShowsIcons = true
        menuBarLayout = .inline
        menuBarDecimals = 0
        greetingUsesName = false
        showsTechnicalDetails = false
        hidesDockIcon = false
        menuBarItems = MenuBarItemConfiguration.defaults
        favoriteSensors = []
        sensorNicknames = [:]
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
