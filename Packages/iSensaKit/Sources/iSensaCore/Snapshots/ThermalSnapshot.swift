import Foundation

/// Thermal state as decided by macOS itself (same scale as `ProcessInfo.ThermalState`).
public enum ThermalLevel: Int, Sendable, Codable, Comparable {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3

    public static func < (lhs: ThermalLevel, rhs: ThermalLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// System-wide thermal pressure (`OSThermalNotification` levels).
public enum ThermalPressure: Int, Sendable, Codable, Comparable {
    case nominal = 0
    case moderate = 1
    case heavy = 2
    case trapping = 3
    case sleeping = 4

    public static func < (lhs: ThermalPressure, rhs: ThermalPressure) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct ThermalSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let level: ThermalLevel
    public let pressure: ThermalPressure?

    public init(timestamp: Date, level: ThermalLevel, pressure: ThermalPressure?) {
        self.timestamp = timestamp
        self.level = level
        self.pressure = pressure
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.thermal = self }
    public var readings: [Reading] { [] }
}
