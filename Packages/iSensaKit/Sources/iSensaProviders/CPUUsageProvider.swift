import Foundation
import iSensaCore
import iSensaHardware

/// Pure tick-delta math, separated from the system call for testability.
enum CPUUsageCalculator {
    struct Usage: Equatable {
        var total: Double
        var user: Double
        var system: Double
        var perCore: [Double]
    }

    /// Counters are 32-bit and may wrap; deltas use wrapping arithmetic on the low 32 bits.
    static func usage(previous: [CPUTicks], current: [CPUTicks]) -> Usage? {
        guard previous.count == current.count, !current.isEmpty else { return nil }
        var user: UInt64 = 0, system: UInt64 = 0, busy: UInt64 = 0, total: UInt64 = 0
        var perCore: [Double] = []
        for (old, new) in zip(previous, current) {
            let deltaUser = delta(old.user, new.user) + delta(old.nice, new.nice)
            let deltaSystem = delta(old.system, new.system)
            let deltaIdle = delta(old.idle, new.idle)
            let coreTotal = deltaUser + deltaSystem + deltaIdle
            perCore.append(coreTotal > 0 ? Double(deltaUser + deltaSystem) / Double(coreTotal) : 0)
            user += deltaUser
            system += deltaSystem
            busy += deltaUser + deltaSystem
            total += coreTotal
        }
        guard total > 0 else { return Usage(total: 0, user: 0, system: 0, perCore: perCore) }
        return Usage(
            total: Double(busy) / Double(total),
            user: Double(user) / Double(total),
            system: Double(system) / Double(total),
            perCore: perCore
        )
    }

    private static func delta(_ old: UInt64, _ new: UInt64) -> UInt64 {
        UInt64(UInt32(truncatingIfNeeded: new) &- UInt32(truncatingIfNeeded: old))
    }
}

/// CPU utilisation from `host_processor_info` (public Mach API).
public actor CPUUsageProvider: MetricProvider {
    public nonisolated let id = "cpu.usage"
    public nonisolated let feature = Feature.cpuUsage
    public nonisolated let tier = SamplingTier.fast

    private let topology: CPUTopology
    private var previous: [CPUTicks]?

    public init(topology: CPUTopology) {
        self.topology = topology
    }

    public func probe() async -> CapabilityState {
        MachHost.cpuTicks() == nil ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        guard let current = MachHost.cpuTicks() else { throw ProviderError.readFailed("host_processor_info") }
        defer { previous = current }
        let usage = previous.flatMap { CPUUsageCalculator.usage(previous: $0, current: current) }
            ?? CPUUsageCalculator.Usage(total: 0, user: 0, system: 0, perCore: Array(repeating: 0, count: current.count))
        let cores = usage.perCore.enumerated().map {
            CPUSnapshot.Core(id: $0.offset, kind: topology.kind(ofCore: $0.offset), usage: $0.element)
        }
        return CPUSnapshot(
            timestamp: Date(),
            totalUsage: usage.total,
            userUsage: usage.user,
            systemUsage: usage.system,
            cores: cores,
            loadAverage: MachHost.loadAverage()
        )
    }
}
