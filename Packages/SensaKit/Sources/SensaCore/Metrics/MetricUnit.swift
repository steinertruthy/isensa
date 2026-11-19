import Foundation

/// Physical or logical unit of a metric value. Values are always stored in the
/// canonical unit listed for each case; conversion happens only at presentation.
public enum MetricUnit: String, Sendable, Codable, Hashable {
    /// Fraction in `0...1`.
    case fraction
    case celsius
    case rpm
    case watts
    case volts
    case amperes
    case milliampereHours
    case bytes
    case bytesPerSecond
    case hertz
    case count
    case seconds
}
