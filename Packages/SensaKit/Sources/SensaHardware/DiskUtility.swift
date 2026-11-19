import Foundation

/// What `diskutil info` says about the disk behind a mounted volume.
public struct DiskDetails: Sendable, Equatable {
    /// "Apple Fabric", "PCI-Express", "USB", "Thunderbolt", "Disk Image"…
    public var busProtocol: String?
    public var apfsContainer: String?
    public var isSolidState: Bool?
}

public struct APFSContainerRecord: Sendable, Equatable {
    public struct Volume: Sendable, Equatable {
        public var identifier: String
        public var name: String
        public var roles: [String]
        public var used: UInt64
        public var fileVault: Bool

        public init(identifier: String, name: String, roles: [String], used: UInt64, fileVault: Bool) {
            self.identifier = identifier
            self.name = name
            self.roles = roles
            self.used = used
            self.fileVault = fileVault
        }
    }

    public var identifier: String
    public var capacity: UInt64
    public var free: UInt64
    public var volumes: [Volume]

    public init(identifier: String, capacity: UInt64, free: UInt64, volumes: [Volume]) {
        self.identifier = identifier
        self.capacity = capacity
        self.free = free
        self.volumes = volumes
    }
}

/// Read-only queries through `/usr/sbin/diskutil` (it needs no privileges and its property lists
/// are stable across macOS versions).
public enum DiskUtility {
    private static let path = "/usr/sbin/diskutil"

    public static func details(forMountPoint mountPoint: String) -> DiskDetails? {
        CommandRunner.run(path, ["info", "-plist", mountPoint]).flatMap(parseDetails)
    }

    public static func container(_ identifier: String) -> APFSContainerRecord? {
        CommandRunner.run(path, ["apfs", "list", "-plist", identifier]).flatMap { parseContainer($0, identifier: identifier) }
    }

    static func parseDetails(_ data: Data) -> DiskDetails? {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return nil }
        return DiskDetails(
            busProtocol: (plist["BusProtocol"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            apfsContainer: plist["APFSContainerReference"] as? String,
            isSolidState: plist["SolidState"] as? Bool
        )
    }

    static func parseContainer(_ data: Data, identifier: String) -> APFSContainerRecord? {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let containers = plist["Containers"] as? [[String: Any]],
              let container = containers.first(where: { $0["ContainerReference"] as? String == identifier }) ?? containers.first,
              let capacity = (container["CapacityCeiling"] as? NSNumber)?.uint64Value,
              let free = (container["CapacityFree"] as? NSNumber)?.uint64Value else { return nil }
        let volumes = (container["Volumes"] as? [[String: Any]] ?? []).compactMap { volume -> APFSContainerRecord.Volume? in
            guard let id = volume["DeviceIdentifier"] as? String else { return nil }
            return APFSContainerRecord.Volume(
                identifier: id,
                name: volume["Name"] as? String ?? id,
                roles: volume["Roles"] as? [String] ?? [],
                used: (volume["CapacityInUse"] as? NSNumber)?.uint64Value ?? 0,
                fileVault: volume["FileVault"] as? Bool ?? false
            )
        }
        return APFSContainerRecord(
            identifier: container["ContainerReference"] as? String ?? identifier, capacity: capacity, free: free, volumes: volumes
        )
    }
}

/// APFS snapshots listed by `/usr/bin/tmutil listlocalsnapshots` (no privileges needed).
public enum LocalSnapshots {
    public struct Summary: Sendable, Equatable {
        public var timeMachine: [Date]
        public var systemUpdate: Int
        public var other: Int

        public init(timeMachine: [Date], systemUpdate: Int, other: Int) {
            self.timeMachine = timeMachine
            self.systemUpdate = systemUpdate
            self.other = other
        }
    }

    public static func list(mountPoint: String = "/") -> Summary? {
        CommandRunner.run("/usr/bin/tmutil", ["listlocalsnapshots", mountPoint]).flatMap { String(data: $0, encoding: .utf8) }.map(parse)
    }

    static func parse(_ output: String) -> Summary {
        var summary = Summary(timeMachine: [], systemUpdate: 0, other: 0)
        for line in output.split(whereSeparator: \.isNewline).map({ $0.trimmingCharacters(in: .whitespaces) }) {
            guard line.hasPrefix("com.") else { continue } // Skips the "Snapshots for volume group…" header.
            if line.hasPrefix("com.apple.TimeMachine.") {
                summary.timeMachine.append(timeMachineDate(line) ?? .distantPast)
            } else if line.hasPrefix("com.apple.os.update-") {
                summary.systemUpdate += 1
            } else {
                summary.other += 1
            }
        }
        return summary
    }

    /// `com.apple.TimeMachine.2026-11-19-101500.local` → that moment, in the Mac's time zone.
    static func timeMachineDate(_ name: String) -> Date? {
        let parts = name.split(separator: ".")
        guard parts.count >= 4 else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.date(from: String(parts[3]))
    }
}
