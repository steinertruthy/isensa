import Foundation
import SensaCore

/// Deterministic rules turning a snapshot into insights. Thresholds are explicit,
/// documented and based on signals macOS itself uses — never on raw RAM usage.
public struct HealthEvaluator: Sendable {
    public struct Thresholds: Sendable, Equatable {
        /// Battery charge (discharging) that warrants attention / is critical.
        public var batteryAttention = 0.15
        public var batteryCritical = 0.05
        /// Used fraction of a volume that warrants attention / is critical.
        public var storageAttention = 0.90
        public var storageCritical = 0.97

        public init() {}
    }

    public var thresholds: Thresholds

    public init(thresholds: Thresholds = Thresholds()) {
        self.thresholds = thresholds
    }

    public func evaluate(_ snapshot: SystemSnapshot) -> SystemHealth {
        var items: [InsightItem] = []
        items += memoryItems(snapshot.memory)
        items += thermalItems(snapshot.thermal)
        items += batteryItems(snapshot.battery)
        items += storageItems(snapshot.storage)
        let sorted = items.sorted { $0.level > $1.level }
        return SystemHealth(level: sorted.first?.level ?? .normal, items: sorted)
    }

    /// Memory pressure is the kernel's own judgement of whether RAM is a bottleneck.
    private func memoryItems(_ memory: MemorySnapshot?) -> [InsightItem] {
        guard let memory, memory.pressure != .normal else { return [] }
        let level: HealthLevel = memory.pressure == .critical ? .critical : .attention
        return [InsightItem(insight: .memoryPressure(memory.pressure), level: level, component: .memory)]
    }

    /// `ProcessInfo.thermalState`: `serious` means macOS is already throttling.
    private func thermalItems(_ thermal: ThermalSnapshot?) -> [InsightItem] {
        guard let thermal, thermal.level >= .serious else { return [] }
        let level: HealthLevel = thermal.level == .critical ? .critical : .attention
        return [InsightItem(insight: .thermalState(thermal.level), level: level, component: .cpu)]
    }

    private func batteryItems(_ battery: BatterySnapshot?) -> [InsightItem] {
        guard let battery else { return [] }
        var items: [InsightItem] = []
        if battery.state == .discharging, battery.charge <= thresholds.batteryAttention {
            let level: HealthLevel = battery.charge <= thresholds.batteryCritical ? .critical : .attention
            items.append(InsightItem(insight: .batteryLow(charge: battery.charge), level: level, component: .battery))
        }
        if battery.state == .charging {
            items.append(InsightItem(
                insight: .batteryCharging(charge: battery.charge, minutesToFull: battery.timeToFull),
                level: .normal, component: .battery
            ))
        }
        // Only macOS' own verdict triggers a service message; we never infer it from capacity alone.
        if let condition = battery.systemCondition, !["Good", "Normal"].contains(condition) {
            items.append(InsightItem(insight: .batteryServiceRecommended(condition: condition), level: .attention, component: .battery))
        }
        return items
    }

    private func storageItems(_ storage: StorageSnapshot?) -> [InsightItem] {
        guard let storage else { return [] }
        return storage.volumes
            .filter { $0.isInternal && $0.usedFraction >= thresholds.storageAttention }
            .map { volume in
                let level: HealthLevel = volume.usedFraction >= thresholds.storageCritical ? .critical : .attention
                return InsightItem(
                    insight: .storageNearlyFull(volume: volume.name, usedFraction: volume.usedFraction),
                    level: level, component: .storage
                )
            }
    }
}
