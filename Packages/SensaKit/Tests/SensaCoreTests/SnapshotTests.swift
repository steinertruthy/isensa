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

@Suite("Storage snapshot")
struct StorageSnapshotTests {
    @Test func purgeableIsWhatFinderCountsBeyondTheFreeSpace() {
        let volume = VolumeInfo(
            id: "root", name: "Macintosh HD", mountPoint: "/", totalCapacity: 494_384_795_648, availableCapacity: 17_841_303_616,
            isInternal: true, isRemovable: false, isRoot: true, freeCapacity: 14_618_750_976
        )
        #expect(volume.purgeableCapacity == 3_222_552_640)
        let unknown = VolumeInfo(
            id: "x", name: "x", mountPoint: "/x", totalCapacity: 10, availableCapacity: 5, isInternal: false, isRemovable: true, isRoot: false
        )
        #expect(unknown.purgeableCapacity == nil)
    }

    @Test func recordsUsedSpaceAndSSDWrites() {
        let snapshot = StorageSnapshot(
            timestamp: Date(), volumes: [VolumeInfo(
                id: "root", name: "HD", mountPoint: "/", totalCapacity: 100, availableCapacity: 40, isInternal: true, isRemovable: false, isRoot: true
            )],
            readRate: 1, writeRate: 2,
            activity: DiskOperations(readOperations: 10, writeOperations: 5, readLatency: nil, writeLatency: nil)
        )
        let metrics = Dictionary(uniqueKeysWithValues: snapshot.readings.map { ($0.metric, $0.value) })
        #expect(metrics[.diskUsed] == 60)
        #expect(metrics[.diskReadOperations] == 10)
        #expect(metrics[.ssdWritten] == nil, "Only with SMART data")
        #expect(HistoryMetrics.recorded.contains(.diskUsed) && HistoryMetrics.recorded.contains(.ssdWritten))
    }

    @Test func fileVaultFollowsTheDataVolume() {
        let container = APFSContainerInfo(identifier: "disk3", capacity: 10, freeCapacity: 1, volumes: [
            .init(id: "s1", name: "Macintosh HD", role: .system, usedCapacity: 1, isFileVaultOn: false),
            .init(id: "s5", name: "Data", role: .data, usedCapacity: 8, isFileVaultOn: true)
        ])
        #expect(container.isFileVaultOn == true)
        #expect(APFSContainerInfo(identifier: "disk9", capacity: 1, freeCapacity: 1, volumes: []).isFileVaultOn == nil)
        #expect(APFSContainerInfo.Role(roles: ["VM"]) == .virtualMemory)
    }
}
