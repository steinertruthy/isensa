import Foundation

public struct CPUSnapshot: SnapshotFragment, Equatable {
    public struct Core: Sendable, Equatable, Identifiable {
        public let id: Int
        public let kind: CoreKind
        /// `0...1`
        public let usage: Double

        public init(id: Int, kind: CoreKind, usage: Double) {
            self.id = id
            self.kind = kind
            self.usage = usage
        }
    }

    public let timestamp: Date
    /// `0...1`, averaged over all logical cores.
    public let totalUsage: Double
    public let userUsage: Double
    public let systemUsage: Double
    public let cores: [Core]
    /// 1, 5 and 15 minute load averages.
    public let loadAverage: [Double]

    public init(timestamp: Date, totalUsage: Double, userUsage: Double, systemUsage: Double, cores: [Core], loadAverage: [Double]) {
        self.timestamp = timestamp
        self.totalUsage = totalUsage
        self.userUsage = userUsage
        self.systemUsage = systemUsage
        self.cores = cores
        self.loadAverage = loadAverage
    }

    public func averageUsage(of kind: CoreKind) -> Double? {
        let matching = cores.filter { $0.kind == kind }
        guard !matching.isEmpty else { return nil }
        return matching.map(\.usage).reduce(0, +) / Double(matching.count)
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.cpu = self }

    public var readings: [Reading] {
        let source = Provenance.system(api: "host_processor_info")
        var result = [
            Reading(metric: .cpuUsage, value: totalUsage, unit: .fraction, timestamp: timestamp, provenance: source),
            Reading(metric: .cpuUserUsage, value: userUsage, unit: .fraction, timestamp: timestamp, provenance: source),
            Reading(metric: .cpuSystemUsage, value: systemUsage, unit: .fraction, timestamp: timestamp, provenance: source)
        ]
        result += cores.map {
            Reading(metric: .cpuCoreUsage($0.id), value: $0.usage, unit: .fraction, timestamp: timestamp, provenance: source)
        }
        return result
    }
}
