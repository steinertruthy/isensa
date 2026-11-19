import SensaHardware
import SensaPrivateAPI
import Testing

/// Runs against the real Mac. Skipped automatically where the interface does not exist.
@Suite("Hardware integration", .tags(.hardware))
struct HardwareIntegrationTests {
    @Test func readsCPUTicksForEveryLogicalCore() throws {
        let ticks = try #require(MachHost.cpuTicks())
        #expect(ticks.count == Sysctl.int("hw.logicalcpu"))
    }

    @Test func readsVMStatistics() throws {
        let vm = try #require(MachHost.vmStatistics())
        #expect(vm.pageSize > 0)
        #expect(vm.wired > 0)
    }

    @Test(.enabled(if: Sysctl.int32("hw.optional.arm64") == 1))
    func smcExposesKeys() throws {
        let smc = try SMCConnection()
        #expect(try smc.keyCount() > 100)
    }

    @Test func networkCountersIncludeLoopback() {
        #expect(NetworkCounters.interfaces().contains { $0.isLoopback })
    }
}

extension Tag {
    @Tag static var hardware: Self
}
