import Foundation

/// The APFS container that holds the startup disk: one pool of space shared by several volumes.
public struct APFSContainerInfo: Sendable, Equatable {
    public struct Volume: Sendable, Equatable, Identifiable {
        public let id: String
        public let name: String
        public let role: Role
        public let usedCapacity: UInt64
        public let isFileVaultOn: Bool

        public init(id: String, name: String, role: Role, usedCapacity: UInt64, isFileVaultOn: Bool) {
            self.id = id
            self.name = name
            self.role = role
            self.usedCapacity = usedCapacity
            self.isFileVaultOn = isFileVaultOn
        }
    }

    public enum Role: Sendable, Hashable {
        /// The signed, read-only macOS system.
        case system
        /// Apps, documents and settings.
        case data
        /// Files needed before macOS starts (also FileVault's unlock screen).
        case preboot
        case recovery
        /// Swap files and the sleep image.
        case virtualMemory
        /// Staging area for macOS updates.
        case update
        case other(String)

        public init(roles: [String]) {
            switch roles.first?.lowercased() {
            case "system": self = .system
            case "data": self = .data
            case "preboot": self = .preboot
            case "recovery": self = .recovery
            case "vm": self = .virtualMemory
            case "update": self = .update
            default: self = .other(roles.first ?? "")
            }
        }
    }

    public let identifier: String
    public let capacity: UInt64
    public let freeCapacity: UInt64
    public let volumes: [Volume]

    public init(identifier: String, capacity: UInt64, freeCapacity: UInt64, volumes: [Volume]) {
        self.identifier = identifier
        self.capacity = capacity
        self.freeCapacity = freeCapacity
        self.volumes = volumes
    }

    /// FileVault protects the data volume; `nil` when the container has none (an external disk).
    public var isFileVaultOn: Bool? { volumes.first { $0.role == .data }?.isFileVaultOn }
}

/// APFS snapshots of the startup disk's volume group. macOS removes them on its own when space
/// is needed, so their space counts as purgeable.
public struct LocalSnapshotSummary: Sendable, Equatable {
    /// Hourly local Time Machine snapshots (`com.apple.TimeMachine.…`).
    public let timeMachine: Int
    /// Snapshots kept around a macOS update (`com.apple.os.update-…`).
    public let systemUpdate: Int
    public let other: Int
    public let newestTimeMachine: Date?

    public init(timeMachine: Int, systemUpdate: Int, other: Int, newestTimeMachine: Date?) {
        self.timeMachine = timeMachine
        self.systemUpdate = systemUpdate
        self.other = other
        self.newestTimeMachine = newestTimeMachine
    }

    public var total: Int { timeMachine + systemUpdate + other }
}
