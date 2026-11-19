import Foundation
import iSensaCore
import iSensaPrivateAPI

/// ⚠️ Uses the PRIVATE IOReport "Energy Model" group: average power per SoC rail.
public actor EnergyProvider: MetricProvider {
    public nonisolated let id = "energy"
    public nonisolated let feature = Feature.powerConsumption
    public nonisolated let tier = SamplingTier.medium
    /// Only shown in the main window and popover.
    public nonisolated let minimumDemand = Demand.interactive

    private var sampler: IOReportSampler?
    private var isSetUp = false

    public init() {}

    public func probe() async -> CapabilityState {
        setUp()
        return sampler == nil ? .unsupported : .experimental(.privateInterface)
    }

    public func sample() async throws -> any SnapshotFragment {
        setUp()
        guard let sampler else { throw ProviderError.interfaceUnavailable("IOReport") }
        guard let result = sampler.sample() else { return PowerSnapshot(timestamp: Date(), rails: [:]) }
        return PowerSnapshot(timestamp: Date(), rails: EnergyCalculator.rails(from: result.channels, interval: result.interval))
    }

    private func setUp() {
        guard !isSetUp else { return }
        isSetUp = true
        sampler = IOReportSampler(groups: [("Energy Model", nil)])
    }
}

/// Converts energy-model channel deltas into watts. Pure, testable.
enum EnergyCalculator {
    /// Preferred channel names per rail, most specific first (names observed on M3 Pro).
    static let channelNames: [PowerRail: [String]] = [
        .cpu: ["CPU Energy"],
        .gpu: ["GPU Energy", "GPU"],
        .neuralEngine: ["ANE"],
        .memory: ["DRAM"]
    ]

    static func rails(from channels: [IOReportChannel], interval: TimeInterval) -> [PowerRail: Double] {
        guard interval > 0 else { return [:] }
        var byName: [String: IOReportChannel] = [:]
        for channel in channels where channel.group == "Energy Model" { byName[channel.name] = channel }
        var rails: [PowerRail: Double] = [:]
        for (rail, names) in channelNames {
            guard let channel = names.lazy.compactMap({ byName[$0] }).first,
                  case let .simple(value) = channel.value,
                  let joules = joules(value, unit: channel.unit) else { continue }
            rails[rail] = max(joules / interval, 0)
        }
        return rails
    }

    static func joules(_ value: Int64, unit: String?) -> Double? {
        switch unit {
        case "mJ": Double(value) / 1e3
        case "uJ", "µJ": Double(value) / 1e6
        case "nJ": Double(value) / 1e9
        default: nil
        }
    }
}
