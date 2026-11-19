import Foundation

/// Cumulative bytes transferred by all block storage drivers since boot.
public struct BlockStorageCounters: Sendable, Equatable {
    public var bytesRead: UInt64
    public var bytesWritten: UInt64

    public init(bytesRead: UInt64, bytesWritten: UInt64) {
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
    }
}

public enum BlockStorageStatistics {
    public static func counters() -> BlockStorageCounters {
        IORegistry.properties(ofClass: "IOBlockStorageDriver").reduce(into: BlockStorageCounters(bytesRead: 0, bytesWritten: 0)) { total, properties in
            guard let statistics = properties["Statistics"] as? [String: Any] else { return }
            total.bytesRead &+= (statistics["Bytes (Read)"] as? NSNumber)?.uint64Value ?? 0
            total.bytesWritten &+= (statistics["Bytes (Write)"] as? NSNumber)?.uint64Value ?? 0
        }
    }
}
