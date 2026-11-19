import Foundation
import SensaCore
import SensaHardware

/// Top processes by CPU and memory (public `libproc`). Processes owned by other
/// users are counted as inaccessible instead of being guessed.
public actor ProcessProvider: MetricProvider {
    public nonisolated let id = "processes"
    public nonisolated let feature = Feature.processes
    public nonisolated let tier = SamplingTier.medium
    /// Only shown in the main window and popover.
    public nonisolated let minimumDemand = Demand.interactive

    private let limit: Int
    private var previous: (date: Date, counters: [Int32: ProcessCounters])?
    private var names: [Int32: (startTime: UInt64, name: String)] = [:]

    public init(limit: Int = 8) {
        self.limit = limit
    }

    public func probe() async -> CapabilityState {
        ProcessTable.counters(pid: getpid()) == nil ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        let now = Date()
        let pids = ProcessTable.allPIDs()
        var counters: [Int32: ProcessCounters] = [:]
        for pid in pids {
            if let value = ProcessTable.counters(pid: pid) { counters[pid] = value }
        }
        let usages = ProcessUsageCalculator.usages(
            previous: previous?.counters ?? [:], current: counters,
            interval: previous.map { now.timeIntervalSince($0.date) } ?? 0,
            name: name(for:)
        )
        previous = (now, counters)
        names = names.filter { counters[$0.key] != nil }
        return ProcessSnapshot(
            timestamp: now,
            topByCPU: Array(usages.sorted { $0.cpu > $1.cpu }.prefix(limit)),
            topByMemory: Array(usages.sorted { $0.memory > $1.memory }.prefix(limit)),
            processCount: pids.count,
            inaccessibleCount: pids.count - counters.count
        )
    }

    private func name(for counters: ProcessCounters) -> String {
        if let cached = names[counters.pid], cached.startTime == counters.startTime { return cached.name }
        let name = ProcessTable.name(pid: counters.pid)
        names[counters.pid] = (counters.startTime, name)
        return name
    }
}

/// Counter deltas → per-process rates. Pure, testable.
enum ProcessUsageCalculator {
    static func usages(
        previous: [Int32: ProcessCounters],
        current: [Int32: ProcessCounters],
        interval: TimeInterval,
        name: (ProcessCounters) -> String
    ) -> [ProcessUsage] {
        current.values.map { counters in
            // Only compare with the same process instance (PID reuse changes the start time).
            let earlier = previous[counters.pid].flatMap { $0.startTime == counters.startTime ? $0 : nil }
            var cpu = 0.0
            if let earlier, interval > 0, counters.cpuTime >= earlier.cpuTime {
                cpu = Double(counters.cpuTime - earlier.cpuTime) / 1e9 / interval
            }
            return ProcessUsage(id: counters.pid, name: name(counters), cpu: cpu, memory: counters.physicalFootprint)
        }
    }
}
