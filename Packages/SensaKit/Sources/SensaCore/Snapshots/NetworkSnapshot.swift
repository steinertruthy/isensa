import Foundation

public enum NetworkInterfaceKind: String, Sendable, Codable {
    case wifi, ethernet, cellular, loopback, other
}

public struct NetworkInterfaceInfo: Sendable, Hashable, Identifiable {
    /// BSD name, e.g. `en0`.
    public let id: String
    public let kind: NetworkInterfaceKind
    public let isActive: Bool
    public let ipv4Addresses: [String]
    public let ipv6Addresses: [String]
    /// Raw byte counters as macOS exposes them to apps: truncated to 32 bits and 1 KiB steps
    /// (observed on macOS 26). Only meaningful as deltas — never display them as totals.
    public let totalReceived: UInt64
    public let totalSent: UInt64

    public init(
        id: String, kind: NetworkInterfaceKind, isActive: Bool, ipv4Addresses: [String],
        ipv6Addresses: [String], totalReceived: UInt64, totalSent: UInt64
    ) {
        self.id = id
        self.kind = kind
        self.isActive = isActive
        self.ipv4Addresses = ipv4Addresses
        self.ipv6Addresses = ipv6Addresses
        self.totalReceived = totalReceived
        self.totalSent = totalSent
    }
}

public struct NetworkSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let interfaces: [NetworkInterfaceInfo]
    /// Bytes per second across active non-loopback interfaces. `nil` on the first sample.
    public let downloadRate: Double?
    public let uploadRate: Double?

    public init(timestamp: Date, interfaces: [NetworkInterfaceInfo], downloadRate: Double?, uploadRate: Double?) {
        self.timestamp = timestamp
        self.interfaces = interfaces
        self.downloadRate = downloadRate
        self.uploadRate = uploadRate
    }

    public var primaryInterface: NetworkInterfaceInfo? {
        interfaces.first { $0.isActive && !$0.ipv4Addresses.isEmpty && $0.kind != .loopback && $0.kind != .other }
            ?? interfaces.first { $0.isActive && !$0.ipv4Addresses.isEmpty && $0.kind != .loopback }
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.network = self }

    public var readings: [Reading] {
        let source = Provenance.derived(method: "if_data64 byte counter delta")
        var result: [Reading] = []
        if let downloadRate {
            result.append(Reading(metric: .networkDownload, value: downloadRate, unit: .bytesPerSecond, timestamp: timestamp, provenance: source))
        }
        if let uploadRate {
            result.append(Reading(metric: .networkUpload, value: uploadRate, unit: .bytesPerSecond, timestamp: timestamp, provenance: source))
        }
        return result
    }
}
