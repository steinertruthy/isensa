import Foundation
import iSensaCore
@testable import iSensaInsights
import Testing

@Suite("Health evaluator")
struct HealthEvaluatorTests {
    private let now = Date()
    private let evaluator = HealthEvaluator()

    private func memory(_ pressure: MemoryPressure, used: UInt64 = 95) -> MemorySnapshot {
        MemorySnapshot(
            timestamp: now,
            total: 100,
            app: used,
            wired: 0,
            compressed: 0,
            cached: 0,
            free: 5,
            swapUsed: 0,
            swapTotal: 0,
            pressure: pressure,
            availableLevel: nil
        )
    }

    private func battery(charge: Double, state: ChargeState, condition: String? = "Good") -> BatterySnapshot {
        BatterySnapshot(
            timestamp: now, charge: charge, state: state, isExternalPowerConnected: state != .discharging, cycleCount: nil,
            designCapacity: nil, nominalCapacity: nil, rawMaxCapacity: nil, remainingCapacity: nil, voltage: nil,
            amperage: nil, temperature: nil, timeToEmpty: nil, timeToFull: 30, systemCondition: condition, adapter: nil
        )
    }

    @Test func emptySnapshotIsNormal() {
        #expect(evaluator.evaluate(SystemSnapshot()).isAllNormal)
    }

    @Test func highRAMUsageAloneIsNotAProblem() {
        var snapshot = SystemSnapshot()
        snapshot.memory = memory(.normal, used: 95)
        #expect(evaluator.evaluate(snapshot).isAllNormal)
    }

    @Test(arguments: [(MemoryPressure.warning, HealthLevel.attention), (.critical, .critical)])
    func memoryPressureDrivesMemoryHealth(pressure: MemoryPressure, expected: HealthLevel) {
        var snapshot = SystemSnapshot()
        snapshot.memory = memory(pressure)
        let health = evaluator.evaluate(snapshot)
        #expect(health.level == expected)
        #expect(health.items.first?.insight == .memoryPressure(pressure))
    }

    @Test func thermalFairIsNormalSeriousNeedsAttention() {
        var snapshot = SystemSnapshot()
        snapshot.thermal = ThermalSnapshot(timestamp: now, level: .fair, pressure: nil)
        #expect(evaluator.evaluate(snapshot).isAllNormal)
        snapshot.thermal = ThermalSnapshot(timestamp: now, level: .serious, pressure: nil)
        #expect(evaluator.evaluate(snapshot).level == .attention)
    }

    @Test func batteryRules() {
        var snapshot = SystemSnapshot()
        snapshot.battery = battery(charge: 0.12, state: .discharging)
        #expect(evaluator.evaluate(snapshot).level == .attention)
        snapshot.battery = battery(charge: 0.04, state: .discharging)
        #expect(evaluator.evaluate(snapshot).level == .critical)
        snapshot.battery = battery(charge: 0.04, state: .charging)
        let charging = evaluator.evaluate(snapshot)
        #expect(charging.isAllNormal)
        #expect(charging.items.contains { $0.insight == .batteryCharging(charge: 0.04, minutesToFull: 30) })
        snapshot.battery = battery(charge: 0.8, state: .charged, condition: "Service Recommended")
        #expect(evaluator.evaluate(snapshot).level == .attention)
    }

    @Test func storageOnlyInternalVolumesAboveThreshold() {
        var snapshot = SystemSnapshot()
        let full = VolumeInfo(
            id: "a",
            name: "Macintosh HD",
            mountPoint: "/",
            totalCapacity: 100,
            availableCapacity: 2,
            isInternal: true,
            isRemovable: false,
            isRoot: true
        )
        let externalFull = VolumeInfo(
            id: "b",
            name: "USB",
            mountPoint: "/Volumes/USB",
            totalCapacity: 100,
            availableCapacity: 1,
            isInternal: false,
            isRemovable: true,
            isRoot: false
        )
        snapshot.storage = StorageSnapshot(timestamp: now, volumes: [full, externalFull], readRate: nil, writeRate: nil)
        let health = evaluator.evaluate(snapshot)
        #expect(health.level == .critical)
        #expect(health.items.count == 1)
    }

    @Test func itemsSortedBySeverity() {
        var snapshot = SystemSnapshot()
        snapshot.memory = memory(.warning)
        snapshot.thermal = ThermalSnapshot(timestamp: now, level: .critical, pressure: nil)
        let levels = evaluator.evaluate(snapshot).items.map(\.level)
        #expect(levels == levels.sorted(by: >))
    }
}

@Suite("SSD insights")
struct SSDInsightTests {
    private func storage(warning: UInt8, mediaErrors: UInt64) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        let health = SSDHealth(
            criticalWarning: warning, temperature: nil, availableSpare: 100, availableSpareThreshold: 10, percentageUsed: 3,
            bytesRead: 0, bytesWritten: 0, powerOnHours: 0, powerCycles: 0, unsafeShutdowns: 0, mediaErrors: mediaErrors
        )
        snapshot.storage = StorageSnapshot(timestamp: Date(), volumes: [], readRate: nil, writeRate: nil, ssdHealth: health)
        return snapshot
    }

    @Test func healthyDriveIsNormal() {
        #expect(HealthEvaluator().evaluate(storage(warning: 0, mediaErrors: 0)).isAllNormal)
    }

    @Test func driveWarningIsCritical() {
        #expect(HealthEvaluator().evaluate(storage(warning: 4, mediaErrors: 0)).level == .critical)
    }

    @Test func mediaErrorsNeedAttention() {
        let health = HealthEvaluator().evaluate(storage(warning: 0, mediaErrors: 2))
        #expect(health.level == .attention)
        #expect(health.items.first?.insight == .ssdMediaErrors(count: 2))
    }
}
