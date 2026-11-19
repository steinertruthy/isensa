import Foundation

/// Activity of one processor cluster during the last interval, derived from the time
/// spent in each hardware performance state.
public struct ClusterActivity: Sendable, Equatable, Identifiable {
    public enum Kind: String, Sendable, Codable {
        case efficiency, performance, gpu
    }

    public let kind: Kind
    /// Residency-weighted average frequency while active, in MHz. `nil` if the state→frequency
    /// mapping could not be validated for this chip (never guessed).
    public let averageFrequency: Double?
    /// Highest frequency of the cluster's DVFS table, in MHz.
    public let maximumFrequency: Double?
    /// Share of the interval spent in an active (non-idle) state, `0...1`.
    public let activeResidency: Double

    public init(kind: Kind, averageFrequency: Double?, maximumFrequency: Double?, activeResidency: Double) {
        self.kind = kind
        self.averageFrequency = averageFrequency
        self.maximumFrequency = maximumFrequency
        self.activeResidency = activeResidency
    }

    public var id: Kind { kind }
}

public struct PerformanceSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let clusters: [ClusterActivity]

    public init(timestamp: Date, clusters: [ClusterActivity]) {
        self.timestamp = timestamp
        self.clusters = clusters
    }

    public func cluster(_ kind: ClusterActivity.Kind) -> ClusterActivity? {
        clusters.first { $0.kind == kind }
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.performance = self }

    public var readings: [Reading] {
        let provenance = Provenance.derived(method: "IOReport residency × DVFS table")
        return clusters.compactMap { cluster in
            cluster.averageFrequency.map {
                Reading(metric: .frequency(cluster.kind), value: $0 * 1_000_000, unit: .hertz, timestamp: timestamp, provenance: provenance)
            }
        }
    }
}
