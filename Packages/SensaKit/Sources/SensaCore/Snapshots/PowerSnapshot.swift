import Foundation

/// Power domains reported by the SoC energy model.
public enum PowerRail: String, Sendable, Codable, CaseIterable {
    case cpu, gpu, neuralEngine, memory
}

public struct PowerSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    /// Average watts per rail over the last interval. Missing rails are not reported by this chip.
    public let rails: [PowerRail: Double]

    public init(timestamp: Date, rails: [PowerRail: Double]) {
        self.timestamp = timestamp
        self.rails = rails
    }

    /// Sum of the reported SoC rails (not the whole system — see `SensorSnapshot.systemPower`).
    public var socTotal: Double { rails.values.reduce(0, +) }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.power = self }

    public var readings: [Reading] {
        let provenance = Provenance.derived(method: "IOReport energy delta ÷ interval")
        return rails.map { Reading(metric: .power($0.key), value: $0.value, unit: .watts, timestamp: timestamp, provenance: provenance) }
    }
}
