import Foundation
import iSensaCore
import iSensaHardware

/// Memory breakdown matching Activity Monitor's definitions (public Mach/sysctl APIs).
public struct MemoryProvider: MetricProvider {
    public let id = "memory"
    public let feature = Feature.memory
    public let tier = SamplingTier.medium

    private let physicalMemory: UInt64

    public init(physicalMemory: UInt64) {
        self.physicalMemory = physicalMemory
    }

    public func probe() async -> CapabilityState {
        MachHost.vmStatistics() == nil ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        guard let vm = MachHost.vmStatistics() else { throw ProviderError.readFailed("host_statistics64") }
        let swap = Sysctl.swapUsage()
        let kernel = KernelMemoryState(
            swapUsed: swap?.xsu_used ?? 0,
            swapTotal: swap?.xsu_total ?? 0,
            pressureLevel: Sysctl.int32("kern.memorystatus_vm_pressure_level"),
            availableLevel: Sysctl.int32("kern.memorystatus_level").map { Double($0) / 100 }
        )
        return Self.snapshot(vm: vm, total: physicalMemory, kernel: kernel, timestamp: Date())
    }

    /// Swap and pressure values reported by the kernel through sysctl.
    struct KernelMemoryState {
        var swapUsed: UInt64
        var swapTotal: UInt64
        var pressureLevel: Int32?
        var availableLevel: Double?
    }

    static func snapshot(vm: VMStatistics, total: UInt64, kernel: KernelMemoryState, timestamp: Date) -> MemorySnapshot {
        let app = vm.internalPages > vm.purgeable ? vm.internalPages - vm.purgeable : 0
        return MemorySnapshot(
            timestamp: timestamp,
            total: total,
            app: app,
            wired: vm.wired,
            compressed: vm.compressed,
            cached: vm.external + vm.purgeable,
            free: vm.free,
            swapUsed: kernel.swapUsed,
            swapTotal: kernel.swapTotal,
            pressure: kernel.pressureLevel.flatMap { MemoryPressure(rawValue: Int($0)) } ?? .normal,
            availableLevel: kernel.availableLevel.map { min(max($0, 0), 1) }
        )
    }
}
