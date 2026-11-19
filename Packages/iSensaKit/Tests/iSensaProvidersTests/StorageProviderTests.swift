import Foundation
import iSensaCore
import iSensaHardware
@testable import iSensaProviders
import Testing

@Suite("Storage provider")
struct StorageProviderTests {
    @Test func operationsAndLatencyFromCounterDeltas() throws {
        let old = BlockStorageCounters(bytesRead: 0, bytesWritten: 0, readOperations: 1_000, writeOperations: 500, readTime: 1_000_000, writeTime: 0)
        let new = BlockStorageCounters(bytesRead: 0, bytesWritten: 0, readOperations: 1_400, writeOperations: 500, readTime: 201_000_000, writeTime: 0)
        let activity = try #require(DiskActivityCalculator.operations(from: old, to: new, over: 2))
        #expect(activity.readOperations == 200)
        #expect(activity.writeOperations == 0)
        #expect(abs((activity.readLatency ?? 0) - 0.000_5) < 1e-12, "200 ms over 400 reads = 0.5 ms")
        #expect(activity.writeLatency == nil, "No writes: no latency rather than zero")
        #expect(DiskActivityCalculator.operations(from: new, to: old, over: 2) == nil, "A disk that went away")
        #expect(DiskActivityCalculator.operations(from: old, to: new, over: 0) == nil)
    }

    @Test func processDiskRatesUseTheSameProcessInstance() {
        let previous = [Int32(7): ProcessCounters(pid: 7, startTime: 1, cpuTime: 0, physicalFootprint: 0, diskBytesRead: 1_000, diskBytesWritten: 0)]
        let current = [Int32(7): ProcessCounters(pid: 7, startTime: 1, cpuTime: 0, physicalFootprint: 0, diskBytesRead: 5_000, diskBytesWritten: 8_000)]
        let usage = ProcessUsageCalculator.usages(previous: previous, current: current, interval: 2) { _ in "App" }
        #expect(usage.first?.diskRead == 2_000)
        #expect(usage.first?.diskWrite == 4_000)
        let reused = [Int32(7): ProcessCounters(pid: 7, startTime: 2, cpuTime: 0, physicalFootprint: 0, diskBytesRead: 9_000, diskBytesWritten: 9_000)]
        #expect(ProcessUsageCalculator.usages(previous: previous, current: reused, interval: 2) { _ in "App" }.first?.diskTotal == 0)
    }

    @Test func mapsTheContainerAndSnapshots() {
        let record = APFSContainerRecord(identifier: "disk3", capacity: 100, free: 10, volumes: [
            .init(identifier: "disk3s5", name: "Data", roles: ["Data"], used: 60, fileVault: true),
            .init(identifier: "disk3s6", name: "VM", roles: ["VM"], used: 5, fileVault: false)
        ])
        let container = StorageProvider.container(record)
        #expect(container.volumes.map(\.role) == [.data, .virtualMemory])
        #expect(container.isFileVaultOn == true)
        let times = [Date(timeIntervalSince1970: 5), Date(timeIntervalSince1970: 9)]
        let snapshots = StorageProvider.snapshots(.init(timeMachine: times, systemUpdate: 1, other: 0))
        #expect(snapshots.total == 3)
        #expect(snapshots.newestTimeMachine == Date(timeIntervalSince1970: 9))
    }

    @Test(.tags(.hardware)) func readsTheStartupDiskOfThisMac() async throws {
        let provider = StorageProvider()
        _ = try await provider.sample()
        try await Task.sleep(for: .milliseconds(300))
        let snapshot = try #require(try await provider.sample() as? StorageSnapshot)
        let root = try #require(snapshot.rootVolume)
        #expect(root.freeCapacity != nil)
        #expect(root.connection == .appleFabric || root.connection == .pciExpress)
        #expect(snapshot.container?.volumes.contains { $0.role == .data } == true)
        #expect(snapshot.localSnapshots != nil)
        #expect(snapshot.activity != nil)
        #expect(snapshot.volumes.allSatisfy { $0.connection != .diskImage }, "Disk images are listed apart")
    }

    @Test(.tags(.hardware), .enabled(if: HardwareDiscovery.discover().modelIdentifier == "Mac15,6"))
    func ssdTemperatureSensorAgreesWithSMART() async throws {
        let sensors = SensorProvider(profile: HardwareDiscovery.discover())
        await sensors.prepare(for: .interactive)
        let snapshot = try #require(try await sensors.sample() as? SensorSnapshot)
        let nand = try #require(snapshot.sensors.first { $0.sensor.group == .storage && $0.sensor.kind == .temperature })
        let smart = try #require(NVMeHealthReader.read()?.temperatureCelsius)
        #expect(abs(nand.value - smart) < 3, "NAND \(nand.value) °C vs SMART \(smart) °C")
    }

    @Test(.tags(.hardware)) func speedTestWritesReadsAndCleansUp() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("isensa-speed-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = try await DiskSpeedTester().run(in: directory, bytes: 64 << 20) { _ in }
        #expect(result.writeSpeed > 0 && result.readSpeed > 0)
        #expect(result.bytes == 64 << 20)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty, "The test file is deleted")
    }

    @Test func connectionNamesFromDiskutil() {
        #expect(StorageConnection(busProtocol: "USB") == .usb)
        #expect(StorageConnection(busProtocol: "Disk Image") == .diskImage)
        #expect(StorageConnection(busProtocol: "Apple Fabric") == .appleFabric)
        #expect(StorageConnection(busProtocol: "FireWire") == .other("FireWire"))
    }
}
