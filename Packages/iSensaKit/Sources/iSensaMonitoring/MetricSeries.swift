import Foundation
import Observation
import iSensaCore

/// Fixed-capacity live series for one metric. Each series is its own observable object,
/// so a chart re-renders only when *its* data changes.
@MainActor
@Observable
public final class MetricSeries: Identifiable {
    public struct Sample: Sendable, Hashable, Identifiable {
        public let timestamp: Date
        public let value: Double
        public var id: Date { timestamp }
    }

    public nonisolated let id: MetricID
    public private(set) var samples: [Sample] = []
    public private(set) var unit: MetricUnit
    public private(set) var provenance: Provenance?
    public let capacity: Int

    public init(id: MetricID, unit: MetricUnit, capacity: Int) {
        self.id = id
        self.unit = unit
        self.capacity = capacity
        samples.reserveCapacity(capacity)
    }

    public var latest: Double? { samples.last?.value }

    public func append(_ reading: Reading) {
        if samples.count >= capacity { samples.removeFirst(samples.count - capacity + 1) }
        samples.append(Sample(timestamp: reading.timestamp, value: reading.value))
        unit = reading.unit
        provenance = reading.provenance
    }

    /// Minimum, maximum and mean over the retained window.
    public var statistics: (minimum: Double, maximum: Double, mean: Double)? {
        guard let first = samples.first?.value else { return nil }
        var minimum = first, maximum = first, sum = 0.0
        for sample in samples {
            minimum = min(minimum, sample.value)
            maximum = max(maximum, sample.value)
            sum += sample.value
        }
        return (minimum, maximum, sum / Double(samples.count))
    }
}
