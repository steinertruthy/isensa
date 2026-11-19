import Foundation

public struct VolumeInfo: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let mountPoint: String
    public let totalCapacity: UInt64
    /// Space available for important usage (includes purgeable space macOS can free).
    public let availableCapacity: UInt64
    public let isInternal: Bool
    public let isRemovable: Bool
    public let isRoot: Bool

    public init(
        id: String, name: String, mountPoint: String, totalCapacity: UInt64,
        availableCapacity: UInt64, isInternal: Bool, isRemovable: Bool, isRoot: Bool
    ) {
        self.id = id
        self.name = name
        self.mountPoint = mountPoint
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.isInternal = isInternal
        self.isRemovable = isRemovable
        self.isRoot = isRoot
    }

    public var usedCapacity: UInt64 { totalCapacity > availableCapacity ? totalCapacity - availableCapacity : 0 }
    public var usedFraction: Double { totalCapacity > 0 ? Double(usedCapacity) / Double(totalCapacity) : 0 }
}

public struct StorageSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let volumes: [VolumeInfo]
    /// Bytes per second across all block storage drivers. `nil` on the first sample.
    public let readRate: Double?
    public let writeRate: Double?
    /// SMART log of the internal SSD, when the drive exposes it.
    public let ssdHealth: SSDHealth?

    public init(timestamp: Date, volumes: [VolumeInfo], readRate: Double?, writeRate: Double?, ssdHealth: SSDHealth? = nil) {
        self.timestamp = timestamp
        self.volumes = volumes
        self.readRate = readRate
        self.writeRate = writeRate
        self.ssdHealth = ssdHealth
    }

    public var rootVolume: VolumeInfo? { volumes.first(where: \.isRoot) }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.storage = self }

    public var readings: [Reading] {
        let source = Provenance.derived(method: "IOBlockStorageDriver statistics delta")
        var result: [Reading] = []
        if let readRate {
            result.append(Reading(metric: .diskRead, value: readRate, unit: .bytesPerSecond, timestamp: timestamp, provenance: source))
        }
        if let writeRate {
            result.append(Reading(metric: .diskWrite, value: writeRate, unit: .bytesPerSecond, timestamp: timestamp, provenance: source))
        }
        return result
    }
}
