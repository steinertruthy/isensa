import Foundation

/// User-tunable alert rules. Every rule has a threshold, a minimum duration before it fires,
/// hysteresis before it can clear, and a shared repeat interval — so notifications stay rare.
public struct AlertConfiguration: Codable, Equatable, Sendable {
    public struct Rule: Codable, Equatable, Sendable {
        public var isEnabled: Bool
        /// Meaning depends on the rule: °C, a fraction `0...1`, or unused for state rules.
        public var threshold: Double

        public init(isEnabled: Bool, threshold: Double = 0) {
            self.isEnabled = isEnabled
            self.threshold = threshold
        }
    }

    /// Master switch; individual rules only matter when this is on.
    public var isEnabled = false
    /// CPU temperature in °C, sustained for `sustainedSeconds`.
    public var highTemperature = Rule(isEnabled: true, threshold: 95)
    /// Fires on the kernel's warning or critical memory pressure.
    public var memoryPressure = Rule(isEnabled: true)
    /// Free fraction of the startup disk.
    public var lowStorage = Rule(isEnabled: true, threshold: 0.10)
    /// Battery charge while discharging.
    public var lowBattery = Rule(isEnabled: true, threshold: 0.20)
    /// Battery charge reached while charging (useful to unplug manually).
    public var batteryCharged = Rule(isEnabled: false, threshold: 0.80)
    /// Battery temperature in °C.
    public var batteryTemperature = Rule(isEnabled: true, threshold: 45)
    /// The startup disk lost at least this much free space (bytes) within `storageGrowthWindow`.
    public var storageFillingFast = Rule(isEnabled: true, threshold: 10_000_000_000)
    /// The SSD reports a critical condition through SMART.
    public var ssdHealth = Rule(isEnabled: true)
    /// A sensor source becomes temporarily unavailable.
    public var sensorUnavailable = Rule(isEnabled: false)
    /// How long a condition must hold before alerting (seconds).
    public var sustainedSeconds: Double = 60
    /// Minimum time before the same alert can be sent again (seconds).
    public var repeatInterval: Double = 1_800

    /// Window over which `storageFillingFast` measures lost free space (seconds).
    public static let storageGrowthWindow: TimeInterval = 1_800

    public init() {}

    // Decoded field by field so preferences saved by an older version keep their values and
    // rules added later start from their defaults.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AlertConfiguration()
        func value<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T { (try? container.decodeIfPresent(T.self, forKey: key)) ?? fallback }
        isEnabled = value(.isEnabled, defaults.isEnabled)
        highTemperature = value(.highTemperature, defaults.highTemperature)
        memoryPressure = value(.memoryPressure, defaults.memoryPressure)
        lowStorage = value(.lowStorage, defaults.lowStorage)
        storageFillingFast = value(.storageFillingFast, defaults.storageFillingFast)
        lowBattery = value(.lowBattery, defaults.lowBattery)
        batteryCharged = value(.batteryCharged, defaults.batteryCharged)
        batteryTemperature = value(.batteryTemperature, defaults.batteryTemperature)
        ssdHealth = value(.ssdHealth, defaults.ssdHealth)
        sensorUnavailable = value(.sensorUnavailable, defaults.sensorUnavailable)
        sustainedSeconds = value(.sustainedSeconds, defaults.sustainedSeconds)
        repeatInterval = value(.repeatInterval, defaults.repeatInterval)
    }
}
