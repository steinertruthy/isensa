import Foundation
import SensaCore

/// A verifiable observation about the Mac. Insights are semantic values — the
/// presentation layer turns them into friendly, localized sentences.
public enum Insight: Hashable, Sendable {
    case memoryPressure(MemoryPressure)
    case thermalState(ThermalLevel)
    case batteryLow(charge: Double)
    case batteryCharging(charge: Double, minutesToFull: Int?)
    case batteryServiceRecommended(condition: String)
    case storageNearlyFull(volume: String, usedFraction: Double)
    /// The SSD itself reports a critical condition (NVMe critical warning or spare below threshold).
    case ssdCriticalWarning
    case ssdMediaErrors(count: UInt64)
}

public struct InsightItem: Hashable, Sendable, Identifiable {
    public let insight: Insight
    public let level: HealthLevel
    public let component: ComponentGroup

    public init(insight: Insight, level: HealthLevel, component: ComponentGroup) {
        self.insight = insight
        self.level = level
        self.component = component
    }

    public var id: Insight { insight }
}

/// Overall assessment shown at the top of the dashboard.
public struct SystemHealth: Hashable, Sendable {
    public let level: HealthLevel
    /// Sorted from most to least severe.
    public let items: [InsightItem]

    public init(level: HealthLevel, items: [InsightItem]) {
        self.level = level
        self.items = items
    }

    /// `true` when nothing needs attention (informational items may still exist).
    public var isAllNormal: Bool { level == .normal }
}
