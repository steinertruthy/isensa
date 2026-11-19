import Foundation

public struct VolumeInfo: Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let mountPoint: String
    public let totalCapacity: UInt64
    /// Space available for important usage (includes purgeable space macOS can free), as Finder shows it.
    public let availableCapacity: UInt64
    /// Space free right now, without asking macOS to purge anything.
    public let freeCapacity: UInt64?
    public let isInternal: Bool
    public let isRemovable: Bool
    public let isRoot: Bool
    public let isEjectable: Bool
    /// The file system, as macOS names it ("APFS", "Mac OS Extended", "ExFAT"…).
    public let formatName: String?
    public let connection: StorageConnection?

    public init(
        id: String, name: String, mountPoint: String, totalCapacity: UInt64,
        availableCapacity: UInt64, isInternal: Bool, isRemovable: Bool, isRoot: Bool,
        freeCapacity: UInt64? = nil, isEjectable: Bool = false, formatName: String? = nil, connection: StorageConnection? = nil
    ) {
        self.id = id
        self.name = name
        self.mountPoint = mountPoint
        self.totalCapacity = totalCapacity
        self.availableCapacity = availableCapacity
        self.freeCapacity = freeCapacity
        self.isInternal = isInternal
        self.isRemovable = isRemovable
        self.isRoot = isRoot
        self.isEjectable = isEjectable
        self.formatName = formatName
        self.connection = connection
    }

    public var usedCapacity: UInt64 { totalCapacity > availableCapacity ? totalCapacity - availableCapacity : 0 }
    public var usedFraction: Double { totalCapacity > 0 ? Double(usedCapacity) / Double(totalCapacity) : 0 }
    /// Space macOS can free on its own (caches, local snapshots, iCloud files kept offline): the
    /// difference between what Finder calls available and what is free right now.
    public var purgeableCapacity: UInt64? {
        freeCapacity.map { availableCapacity > $0 ? availableCapacity - $0 : 0 }
    }
}

public struct StorageSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    /// Writable volumes (and the startup disk).
    public let volumes: [VolumeInfo]
    /// Mounted disk images (installers and the like), listed apart so they can be ejected.
    public let diskImages: [VolumeInfo]
    /// Bytes per second across all block storage drivers. `nil` on the first sample.
    public let readRate: Double?
    public let writeRate: Double?
    public let activity: DiskOperations?
    /// SMART log of the internal SSD, when the drive exposes it.
    public let ssdHealth: SSDHealth?
    /// The APFS container of the startup disk.
    public let container: APFSContainerInfo?
    public let localSnapshots: LocalSnapshotSummary?

    public init(
        timestamp: Date, volumes: [VolumeInfo], readRate: Double?, writeRate: Double?, ssdHealth: SSDHealth? = nil,
        diskImages: [VolumeInfo] = [], activity: DiskOperations? = nil, container: APFSContainerInfo? = nil,
        localSnapshots: LocalSnapshotSummary? = nil
    ) {
        self.timestamp = timestamp
        self.volumes = volumes
        self.diskImages = diskImages
        self.readRate = readRate
        self.writeRate = writeRate
        self.activity = activity
        self.ssdHealth = ssdHealth
        self.container = container
        self.localSnapshots = localSnapshots
    }

    public var rootVolume: VolumeInfo? { volumes.first(where: \.isRoot) }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.storage = self }

    public var readings: [Reading] {
        let source = Provenance.derived(method: "IOBlockStorageDriver statistics delta")
        var result: [Reading] = []
        func add(_ metric: MetricID, _ value: Double?, _ unit: MetricUnit, _ provenance: Provenance = source) {
            guard let value else { return }
            result.append(Reading(metric: metric, value: value, unit: unit, timestamp: timestamp, provenance: provenance))
        }
        add(.diskRead, readRate, .bytesPerSecond)
        add(.diskWrite, writeRate, .bytesPerSecond)
        add(.diskReadOperations, activity?.readOperations, .perSecond)
        add(.diskWriteOperations, activity?.writeOperations, .perSecond)
        add(.diskUsed, rootVolume.map { Double($0.usedCapacity) }, .bytes, .system(api: "URLResourceValues"))
        add(.ssdWritten, ssdHealth.map { Double($0.bytesWritten) }, .bytes, .hardware(source: "NVMe SMART log"))
        return result
    }
}

/// Operations per second and average service time over the last sample interval.
public struct DiskOperations: Sendable, Equatable {
    public let readOperations: Double
    public let writeOperations: Double
    /// Average time per completed read or write, seconds; `nil` when there was none.
    public let readLatency: Double?
    public let writeLatency: Double?

    public init(readOperations: Double, writeOperations: Double, readLatency: Double?, writeLatency: Double?) {
        self.readOperations = readOperations
        self.writeOperations = writeOperations
        self.readLatency = readLatency
        self.writeLatency = writeLatency
    }
}

/// How a disk is attached, as macOS reports it.
public enum StorageConnection: Sendable, Hashable {
    case appleFabric, pciExpress, usb, thunderbolt, sata, diskImage, network, virtual
    case other(String)

    public init(busProtocol: String) {
        switch busProtocol.lowercased() {
        case "apple fabric": self = .appleFabric
        case "pci-express", "pci": self = .pciExpress
        case "usb": self = .usb
        case "thunderbolt": self = .thunderbolt
        case "sata", "ata": self = .sata
        case "disk image": self = .diskImage
        case "network", "smb", "afp", "nfs": self = .network
        case "virtual interface": self = .virtual
        default: self = .other(busProtocol)
        }
    }
}
