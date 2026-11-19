import Foundation
import SensaCore
import Testing

@Suite("Snapshots")
struct SnapshotTests {
    private let now = Date(timeIntervalSince1970: 1_000)

    @Test func memoryUsedMatchesActivityMonitorDefinition() {
        let memory = MemorySnapshot(
            timestamp: now, total: 100, app: 30, wired: 10, compressed: 5, cached: 40, free: 15,
            swapUsed: 0, swapTotal: 0, pressure: .normal, availableLevel: 0.7
        )
        #expect(memory.used == 45)
        #expect(memory.usedFraction == 0.45)
        #expect(abs((memory.pressureFraction ?? 0) - 0.3) < 1e-9)
    }

    @Test func batteryDerivedValues() {
        let battery = BatterySnapshot(
            timestamp: now, charge: 0.5, state: .discharging, isExternalPowerConnected: false,
            cycleCount: 10, designCapacity: 6_000, nominalCapacity: 5_400, rawMaxCapacity: 5_300,
            remainingCapacity: 2_700, voltage: 12, amperage: -0.5, temperature: 30,
            timeToEmpty: 120, timeToFull: nil, systemCondition: "Good", adapter: nil
        )
        #expect(battery.health == 0.9)
        #expect(battery.power == -6)
        let power = battery.readings.first { $0.metric == .batteryPower }
        #expect(power?.provenance == .derived(method: "voltage × amperage"))
    }

    @Test func fragmentsApplyToTheirDomainOnly() {
        var snapshot = SystemSnapshot()
        ThermalSnapshot(timestamp: now, level: .fair, pressure: nil).apply(to: &snapshot)
        #expect(snapshot.thermal?.level == .fair)
        #expect(snapshot.cpu == nil)
    }

    @Test func fanRelativeSpeedIsClamped() {
        let stopped = FanReading(id: 0, currentRPM: 0, minimumRPM: 2_317, maximumRPM: 6_800, targetRPM: 0, isAutomatic: true)
        #expect(stopped.relativeSpeed == 0)
        let half = FanReading(id: 0, currentRPM: 4_000, minimumRPM: 2_000, maximumRPM: 6_000, targetRPM: nil, isAutomatic: true)
        #expect(half.relativeSpeed == 0.5)
    }

    @Test func capabilityStates() {
        #expect(CapabilityState.experimental(.privateInterface).isUsable)
        #expect(!CapabilityState.requiresAuthorization(.signedPrivilegedHelper).isUsable)
        #expect(CapabilityState.requiresAuthorization(.signedPrivilegedHelper).isPresent)
        #expect(!CapabilityState.unavailable.isPresent)
        var map = CapabilityMap()
        #expect(map.isPresent(.fans), "Unprobed features keep their place while discovery runs")
        #expect(!map.isUsable(.fans))
        map[.fans] = .available
        #expect(map.isUsable(.fans))
    }
}
