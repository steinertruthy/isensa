import Foundation

/// Where a value came from. The UI must always be able to tell the user whether
/// a number was measured, computed from other measurements, estimated, or is demo data.
public enum Provenance: Sendable, Hashable, Codable {
    /// Read directly from a hardware controller (SMC, gas gauge, HID sensor hub...).
    case hardware(source: String)
    /// Reported by a macOS API (Mach, sysctl, IOPowerSources...).
    case system(api: String)
    /// Calculated from other measured values (e.g. watts = volts × amperes).
    case derived(method: String)
    /// Model-based estimate that may differ from reality.
    case estimated(method: String)
    /// Synthetic data for demonstrations and UI tests. Never mixed with production providers.
    case demo

    public var isMeasured: Bool {
        switch self {
        case .hardware, .system: true
        case .derived, .estimated, .demo: false
        }
    }
}

/// A single scalar sample for a time series.
public struct Reading: Sendable, Hashable {
    public let metric: MetricID
    public let value: Double
    public let unit: MetricUnit
    public let timestamp: Date
    public let provenance: Provenance

    public init(metric: MetricID, value: Double, unit: MetricUnit, timestamp: Date, provenance: Provenance) {
        self.metric = metric
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.provenance = provenance
    }
}
