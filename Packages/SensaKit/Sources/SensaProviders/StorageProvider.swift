import Foundation
import SensaCore
import SensaHardware

/// Volume capacities (Foundation) and transfer rates (IOBlockStorageDriver counters).
public actor StorageProvider: MetricProvider {
    public nonisolated let id = "storage"
    public nonisolated let feature = Feature.storage
    public nonisolated let tier = SamplingTier.medium

    /// Volume capacity changes slowly; refreshing it on every rate sample would waste I/O.
    private let volumeRefreshInterval: TimeInterval
    private var cachedVolumes: (date: Date, volumes: [VolumeInfo])?
    private var previous: (date: Date, counters: BlockStorageCounters)?

    public init(volumeRefreshInterval: TimeInterval = 30) {
        self.volumeRefreshInterval = volumeRefreshInterval
    }

    public func probe() async -> CapabilityState {
        Volumes.mounted().isEmpty ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        let now = Date()
        let counters = BlockStorageStatistics.counters()
        let rates = previous.flatMap { RateCalculator.rates(
            from: ($0.counters.bytesRead, $0.counters.bytesWritten),
            to: (counters.bytesRead, counters.bytesWritten),
            over: now.timeIntervalSince($0.date)
        ) }
        previous = (now, counters)
        return StorageSnapshot(timestamp: now, volumes: volumes(now: now), readRate: rates?.first, writeRate: rates?.second)
    }

    private func volumes(now: Date) -> [VolumeInfo] {
        if let cachedVolumes, now.timeIntervalSince(cachedVolumes.date) < volumeRefreshInterval {
            return cachedVolumes.volumes
        }
        let volumes = Volumes.mounted().map {
            VolumeInfo(
                id: $0.identifier, name: $0.name, mountPoint: $0.url.path,
                totalCapacity: $0.totalCapacity, availableCapacity: $0.availableCapacity,
                isInternal: $0.isInternal, isRemovable: $0.isRemovable, isRoot: $0.isRoot
            )
        }
        cachedVolumes = (now, volumes)
        return volumes
    }
}

/// Byte counter → bytes/second, tolerant of counter resets (e.g. a disk ejected).
enum RateCalculator {
    static func rates(from old: (UInt64, UInt64), to new: (UInt64, UInt64), over interval: TimeInterval) -> (first: Double, second: Double)? {
        guard interval > 0 else { return nil }
        func rate(_ a: UInt64, _ b: UInt64) -> Double { b >= a ? Double(b - a) / interval : 0 }
        return (rate(old.0, new.0), rate(old.1, new.1))
    }
}
