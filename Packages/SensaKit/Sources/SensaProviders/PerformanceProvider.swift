import Foundation
import SensaCore
import SensaPrivateAPI

/// ⚠️ Uses the PRIVATE IOReport interface. CPU-cluster and GPU frequencies derived from
/// performance-state residency and the power manager's DVFS tables.
public actor PerformanceProvider: MetricProvider {
    public nonisolated let id = "performance"
    public nonisolated let feature = Feature.cpuFrequency
    public nonisolated let tier = SamplingTier.medium
    /// Only shown in the main window and popover.
    public nonisolated let minimumDemand = Demand.interactive

    private var sampler: IOReportSampler?
    private var isSetUp = false
    private var tables: [ClusterActivity.Kind: [Double]] = [:]

    public init() {}

    public func probe() async -> CapabilityState {
        setUp()
        return sampler == nil || tables.isEmpty ? .unsupported : .experimental(.privateInterface)
    }

    public func sample() async throws -> any SnapshotFragment {
        setUp()
        guard let sampler else { throw ProviderError.interfaceUnavailable("IOReport") }
        guard let result = sampler.sample() else {
            // First sample primes the counters.
            return PerformanceSnapshot(timestamp: Date(), clusters: [])
        }
        var grouped: [ClusterActivity.Kind: [[(name: String, residency: Int64)]]] = [:]
        for channel in result.channels {
            guard case let .states(states) = channel.value, let kind = Self.cluster(of: channel) else { continue }
            grouped[kind, default: []].append(states.map { ($0.name, $0.residency) })
        }
        let clusters = [ClusterActivity.Kind.efficiency, .performance, .gpu].compactMap { kind -> ClusterActivity? in
            guard let states = grouped[kind] else { return nil }
            let activity = FrequencyCalculator.activity(states: states, table: tables[kind])
            return ClusterActivity(
                kind: kind,
                averageFrequency: activity.averageFrequency,
                maximumFrequency: tables[kind]?.max(),
                activeResidency: activity.activeResidency
            )
        }
        return PerformanceSnapshot(timestamp: Date(), clusters: clusters)
    }

    static func cluster(of channel: IOReportChannel) -> ClusterActivity.Kind? {
        switch channel.subgroup {
        case "CPU Core Performance States":
            if channel.name.hasPrefix("ECPU") { return .efficiency }
            if channel.name.hasPrefix("PCPU") { return .performance }
            return nil
        case "GPU Performance States":
            return channel.name == "GPUPH" ? .gpu : nil
        default:
            return nil
        }
    }

    private func setUp() {
        guard !isSetUp else { return }
        isSetUp = true
        sampler = IOReportSampler(groups: [
            ("CPU Stats", "CPU Core Performance States"),
            ("GPU Stats", "GPU Performance States")
        ])
        tables[.efficiency] = DVFSTable.read(DVFSTable.efficiencyKey)
        tables[.performance] = DVFSTable.read(DVFSTable.performanceKey)
        tables[.gpu] = DVFSTable.read(DVFSTable.gpuKey)
    }
}
