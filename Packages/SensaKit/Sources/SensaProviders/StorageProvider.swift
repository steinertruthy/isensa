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
    /// SMART data changes slowly; reading it every few minutes is plenty.
    private let healthRefreshInterval: TimeInterval = 300
    private var cachedHealth: (date: Date, health: SSDHealth?)?

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
        return StorageSnapshot(
            timestamp: now, volumes: volumes(now: now), readRate: rates?.first, writeRate: rates?.second, ssdHealth: health(now: now)
        )
    }

    private func health(now: Date) -> SSDHealth? {
        if let cachedHealth, now.timeIntervalSince(cachedHealth.date) < healthRefreshInterval { return cachedHealth.health }
        let health = NVMeHealthReader.read().map(Self.health)
        cachedHealth = (now, health)
        return health
    }

    static func health(_ log: NVMeHealthLog) -> SSDHealth {
        SSDHealth(
            criticalWarning: log.criticalWarning, temperature: log.temperatureCelsius,
            availableSpare: log.availableSpare, availableSpareThreshold: log.availableSpareThreshold,
            percentageUsed: log.percentageUsed, bytesRead: log.bytesRead, bytesWritten: log.bytesWritten,
            powerOnHours: log.powerOnHours, powerCycles: log.powerCycles,
            unsafeShutdowns: log.unsafeShutdowns, mediaErrors: log.mediaErrors
        )
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

/// Byte counter → bytes/second.
///
/// Handles two counter behaviours: 32-bit wrap-around (macOS gives unprivileged apps interface
/// byte counters truncated to 32 bits, observed on macOS 26 / Mac15,6) and resets (a disk
/// ejected, an interface recreated), which yield 0 instead of a bogus spike.
enum RateCalculator {
    static func rates(from old: (UInt64, UInt64), to new: (UInt64, UInt64), over interval: TimeInterval) -> (first: Double, second: Double)? {
        guard interval > 0 else { return nil }
        return (Double(delta(old.0, new.0)) / interval, Double(delta(old.1, new.1)) / interval)
    }

    static func delta(_ old: UInt64, _ new: UInt64) -> UInt64 {
        if new >= old { return new - old }
        let range = UInt64(UInt32.max) + 1
        // A 32-bit counter that wrapped once: the old value sat in the top part of the range.
        if old < range, new < range, old - new > range / 2 { return range - old + new }
        return 0
    }
}
