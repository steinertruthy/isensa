import Foundation
@testable import SensaProviders
import SensaCore
import SensaHardware
import SensaPrivateAPI
import Testing

@Suite("DVFS tables and frequencies")
struct FrequencyTests {
    private func table(_ pairs: [(UInt32, UInt32)]) -> Data {
        var data = Data()
        for (frequency, voltage) in pairs {
            withUnsafeBytes(of: frequency.littleEndian) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: voltage.littleEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    @Test func parsesHertzTablesFromM3Pro() throws {
        // First entries of voltage-states1-sram on Mac15,6.
        let data = table([(744_000_000, 790), (1_044_000_000, 795), (2_748_000_000, 1_040)])
        #expect(try #require(DVFSTable.frequencies(from: data)) == [744, 1_044, 2_748])
    }

    @Test func parsesKilohertzTables() throws {
        #expect(try #require(DVFSTable.frequencies(from: table([(912_000, 800), (4_512_000, 1_100)]))) == [912, 4_512])
    }

    @Test func rejectsImplausibleTables() {
        #expect(DVFSTable.frequencies(from: table([(5, 1), (7, 1)])) == nil)
        #expect(DVFSTable.frequencies(from: Data([1, 2, 3])) == nil)
    }

    @Test(arguments: [("V7P0", 7), ("V19P0", 19), ("V0P7", 0), ("P5", 5), ("IDLE", nil), ("OFF", nil)] as [(String, Int?)])
    func stateIndices(name: String, expected: Int?) {
        #expect(FrequencyCalculator.tableIndex(of: name) == expected)
    }

    @Test func residencyWeightedAverageAcrossCores() {
        let table: [Double] = [1_000, 2_000, 3_000]
        let cores: [[(name: String, residency: Int64)]] = [
            [("IDLE", 50), ("V0P2", 25), ("V2P0", 25)],
            [("IDLE", 100)]
        ]
        let result = FrequencyCalculator.activity(states: cores, table: table)
        #expect(result.averageFrequency == 2_000)
        #expect(result.activeResidency == 0.25)
    }

    @Test func unmappableStateDisablesFrequencyButKeepsActivity() {
        let result = FrequencyCalculator.activity(states: [[("V9P0", 10), ("IDLE", 10)]], table: [1_000])
        #expect(result.averageFrequency == nil, "Never guess a frequency outside the validated table")
        #expect(result.activeResidency == 0.5)
    }
}

@Suite("Energy model")
struct EnergyTests {
    private func channel(_ name: String, _ value: Int64, _ unit: String) -> IOReportChannel {
        IOReportChannel(group: "Energy Model", subgroup: "", name: name, unit: unit, value: .simple(value))
    }

    @Test func convertsUnitsToWatts() {
        // Values observed on Mac15,6 over ~1 s: CPU in mJ, GPU in nJ.
        let rails = EnergyCalculator.rails(from: [
            channel("CPU Energy", 216, "mJ"), channel("GPU Energy", 357_551_847, "nJ"),
            channel("GPU", 364, "mJ"), channel("DRAM", 267, "mJ"), channel("ANE", 0, "mJ")
        ], interval: 2)
        #expect(rails[.cpu] == 0.108)
        #expect(abs((rails[.gpu] ?? 0) - 0.178_775_9235) < 1e-9, "Prefers the GPU Energy channel")
        #expect(rails[.memory] == 0.1335)
        #expect(rails[.neuralEngine] == 0)
    }

    @Test func unknownUnitsAreSkipped() {
        #expect(EnergyCalculator.rails(from: [channel("CPU Energy", 5, "kWh")], interval: 1).isEmpty)
        #expect(EnergyCalculator.rails(from: [channel("CPU Energy", 5, "mJ")], interval: 0).isEmpty)
    }
}

@Suite("Processes")
struct ProcessTests {
    private func counters(_ pid: Int32, start: UInt64 = 1, cpu: UInt64, memory: UInt64 = 10) -> ProcessCounters {
        ProcessCounters(pid: pid, startTime: start, cpuTime: cpu, physicalFootprint: memory)
    }

    @Test func cpuIsCoreSecondsPerSecond() throws {
        let usages = ProcessUsageCalculator.usages(
            previous: [1: counters(1, cpu: 0)], current: [1: counters(1, cpu: 3_000_000_000)], interval: 2, name: { _ in "x" }
        )
        #expect(try #require(usages.first).cpu == 1.5)
    }

    @Test func pidReuseIsNotTreatedAsTheSameProcess() throws {
        let usages = ProcessUsageCalculator.usages(
            previous: [1: counters(1, start: 1, cpu: 0)], current: [1: counters(1, start: 2, cpu: 9_000_000_000)], interval: 1, name: { _ in "x" }
        )
        #expect(try #require(usages.first).cpu == 0)
    }

    @Test(arguments: [
        ("/Applications/Safari.app/Contents/MacOS/Safari", "Safari"),
        ("/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild", "Xcode"),
        ("/usr/sbin/mDNSResponder", "mDNSResponder")
    ])
    func displayNames(path: String, expected: String) {
        #expect(ProcessTable.displayName(forExecutablePath: path) == expected)
    }

    @Test(.tags(.hardware)) func readsOwnProcessCounters() throws {
        let own = try #require(ProcessTable.counters(pid: getpid()))
        #expect(own.physicalFootprint > 0)
    }
}

@Suite("SSD and Wi-Fi")
struct SSDWiFiTests {
    private func health(warning: UInt8 = 0, spare: Int = 100, threshold: Int = 99) -> SSDHealth {
        SSDHealth(
            criticalWarning: warning, temperature: 34, availableSpare: spare, availableSpareThreshold: threshold, percentageUsed: 1,
            bytesRead: 0, bytesWritten: 0, powerOnHours: 690, powerCycles: 269, unsafeShutdowns: 5, mediaErrors: 0
        )
    }

    @Test func criticalConditionComesOnlyFromTheDrive() {
        #expect(!health().reportsCriticalCondition)
        #expect(health(warning: 1).reportsCriticalCondition)
        #expect(health(spare: 5, threshold: 10).reportsCriticalCondition)
    }

    @Test(arguments: [(-34, SignalQuality.excellent), (-65, .good), (-75, .fair), (-85, .poor)])
    func signalQuality(rssi: Int, expected: SignalQuality) {
        let wifi = WiFiSnapshot(
            timestamp: Date(), interfaceName: "en0", isPoweredOn: true, networkName: nil, rssi: rssi, noise: -93,
            transmitRate: 2_401, channel: 112, band: .ghz5, channelWidthMHz: 160, phyMode: nil
        )
        #expect(wifi.signalQuality == expected)
        #expect(wifi.signalToNoise == rssi + 93)
    }
}

extension Tag {
    @Tag static var hardware: Self
}

@Suite("Counter rates")
struct CounterRateTests {
    @Test func handles32BitWrapOfTruncatedInterfaceCounters() {
        // macOS gives apps interface counters truncated to 32 bits (observed on macOS 26).
        let old = UInt64(UInt32.max) - 1_023
        #expect(RateCalculator.delta(old, 1_024) == 2_048)
    }

    @Test func resetsYieldZeroNotASpike() {
        #expect(RateCalculator.delta(5_000_000_000, 10) == 0)
        #expect(RateCalculator.delta(1_000, 900) == 0)
    }

    @Test func tunnelsAreNotCountedAsPhysicalTraffic() {
        #expect(!NetworkProvider.physicalKinds.contains(.other))
        #expect(NetworkProvider.physicalKinds.contains(.wifi))
    }
}
