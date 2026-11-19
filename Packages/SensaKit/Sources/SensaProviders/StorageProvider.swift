import Foundation
import SensaCore
import SensaHardware

/// Volume capacities (Foundation), transfer rates and operations (IOBlockStorageDriver counters),
/// the startup disk's APFS layout (`diskutil`) and local snapshots (`tmutil`).
public actor StorageProvider: MetricProvider {
    public nonisolated let id = "storage"
    public nonisolated let feature = Feature.storage
    public nonisolated let tier = SamplingTier.medium

    /// Volume capacity changes slowly; refreshing it on every rate sample would waste I/O.
    private let volumeRefreshInterval: TimeInterval
    private var cachedVolumes: (date: Date, volumes: [VolumeInfo], diskImages: [VolumeInfo])?
    /// `diskutil` answers per mounted volume; asked once per mount, not on every refresh.
    private var details: [String: DiskDetails] = [:]
    private var previous: (date: Date, counters: BlockStorageCounters)?
    /// SMART data, the APFS layout and snapshots change slowly; every few minutes is plenty.
    private let slowRefreshInterval: TimeInterval = 300
    private var cachedHealth: (date: Date, health: SSDHealth?)?
    private var cachedLayout: (date: Date, container: APFSContainerInfo?, snapshots: LocalSnapshotSummary?)?

    public init(volumeRefreshInterval: TimeInterval = 30) {
        self.volumeRefreshInterval = volumeRefreshInterval
    }

    public func probe() async -> CapabilityState {
        Volumes.mounted().isEmpty ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        let now = Date()
        let counters = BlockStorageStatistics.counters()
        let interval = previous.map { now.timeIntervalSince($0.date) }
        let rates = previous.flatMap { RateCalculator.rates(
            from: ($0.counters.bytesRead, $0.counters.bytesWritten),
            to: (counters.bytesRead, counters.bytesWritten),
            over: now.timeIntervalSince($0.date)
        ) }
        let activity = previous.flatMap { DiskActivityCalculator.operations(from: $0.counters, to: counters, over: interval ?? 0) }
        previous = (now, counters)
        let (volumes, diskImages) = volumes(now: now)
        let layout = layout(now: now, root: volumes.first(where: \.isRoot))
        return StorageSnapshot(
            timestamp: now, volumes: volumes, readRate: rates?.first, writeRate: rates?.second, ssdHealth: health(now: now),
            diskImages: diskImages, activity: activity, container: layout.container, localSnapshots: layout.snapshots
        )
    }

    private func health(now: Date) -> SSDHealth? {
        if let cachedHealth, now.timeIntervalSince(cachedHealth.date) < slowRefreshInterval { return cachedHealth.health }
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

    private func layout(now: Date, root: VolumeInfo?) -> (container: APFSContainerInfo?, snapshots: LocalSnapshotSummary?) {
        if let cachedLayout, now.timeIntervalSince(cachedLayout.date) < slowRefreshInterval {
            return (cachedLayout.container, cachedLayout.snapshots)
        }
        let container = root.flatMap { details[Self.detailsKey($0)]?.apfsContainer }.flatMap(DiskUtility.container).map(Self.container)
        let snapshots = LocalSnapshots.list().map(Self.snapshots)
        cachedLayout = (now, container, snapshots)
        return (container, snapshots)
    }

    static func container(_ record: APFSContainerRecord) -> APFSContainerInfo {
        APFSContainerInfo(
            identifier: record.identifier, capacity: record.capacity, freeCapacity: record.free,
            volumes: record.volumes.map {
                .init(id: $0.identifier, name: $0.name, role: .init(roles: $0.roles), usedCapacity: $0.used, isFileVaultOn: $0.fileVault)
            }
        )
    }

    static func snapshots(_ summary: LocalSnapshots.Summary) -> LocalSnapshotSummary {
        LocalSnapshotSummary(
            timeMachine: summary.timeMachine.count, systemUpdate: summary.systemUpdate, other: summary.other,
            newestTimeMachine: summary.timeMachine.max()
        )
    }

    private func volumes(now: Date) -> (volumes: [VolumeInfo], diskImages: [VolumeInfo]) {
        if let cachedVolumes, now.timeIntervalSince(cachedVolumes.date) < volumeRefreshInterval {
            return (cachedVolumes.volumes, cachedVolumes.diskImages)
        }
        let records = Volumes.mounted()
        let mounted = Set(records.map(Self.detailsKey))
        details = details.filter { mounted.contains($0.key) }
        var volumes: [VolumeInfo] = [], diskImages: [VolumeInfo] = []
        for record in records {
            let key = Self.detailsKey(record)
            if details[key] == nil, let found = DiskUtility.details(forMountPoint: record.url.path) { details[key] = found }
            let connection = details[key]?.busProtocol.map(StorageConnection.init(busProtocol:))
            let volume = VolumeInfo(
                id: record.identifier, name: record.name, mountPoint: record.url.path,
                totalCapacity: record.totalCapacity, availableCapacity: record.availableCapacity,
                isInternal: record.isInternal, isRemovable: record.isRemovable, isRoot: record.isRoot,
                freeCapacity: record.freeCapacity, isEjectable: record.isEjectable && !record.isRoot,
                formatName: record.formatName, connection: connection
            )
            if connection == .diskImage {
                diskImages.append(volume)
            } else if !record.isReadOnly || record.isRoot {
                // Other read-only volumes (recovery, sealed system copies) have no meaningful free space.
                volumes.append(volume)
            }
        }
        cachedVolumes = (now, volumes, diskImages)
        return (volumes, diskImages)
    }

    private static func detailsKey(_ record: VolumeRecord) -> String { record.identifier + record.url.path }
    private static func detailsKey(_ volume: VolumeInfo) -> String { volume.id + volume.mountPoint }
}

/// Counter deltas → operations per second and average time per operation. Pure, testable.
enum DiskActivityCalculator {
    static func operations(from old: BlockStorageCounters, to new: BlockStorageCounters, over interval: TimeInterval) -> DiskOperations? {
        guard interval > 0 else { return nil }
        // A disk that went away makes the sums drop: report nothing for that interval rather than a bogus value.
        guard new.readOperations >= old.readOperations, new.writeOperations >= old.writeOperations,
              new.readTime >= old.readTime, new.writeTime >= old.writeTime else { return nil }
        let reads = new.readOperations - old.readOperations
        let writes = new.writeOperations - old.writeOperations
        return DiskOperations(
            readOperations: Double(reads) / interval,
            writeOperations: Double(writes) / interval,
            readLatency: reads > 0 ? Double(new.readTime - old.readTime) / 1e9 / Double(reads) : nil,
            writeLatency: writes > 0 ? Double(new.writeTime - old.writeTime) / 1e9 / Double(writes) : nil
        )
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
