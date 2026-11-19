import Foundation

/// Cumulative counters of all block storage drivers since boot.
public struct BlockStorageCounters: Sendable, Equatable {
    public var bytesRead: UInt64
    public var bytesWritten: UInt64
    public var readOperations: UInt64
    public var writeOperations: UInt64
    /// Time spent on completed reads and writes, nanoseconds.
    public var readTime: UInt64
    public var writeTime: UInt64

    public init(
        bytesRead: UInt64, bytesWritten: UInt64, readOperations: UInt64 = 0, writeOperations: UInt64 = 0, readTime: UInt64 = 0, writeTime: UInt64 = 0
    ) {
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
        self.readOperations = readOperations
        self.writeOperations = writeOperations
        self.readTime = readTime
        self.writeTime = writeTime
    }
}

public enum BlockStorageStatistics {
    public static func counters() -> BlockStorageCounters {
        sum(IORegistry.properties(ofClass: "IOBlockStorageDriver").compactMap { $0["Statistics"] as? [String: Any] })
    }

    /// Adds up the `Statistics` dictionaries of every driver (internal SSD, external disks, disk images).
    static func sum(_ statistics: [[String: Any]]) -> BlockStorageCounters {
        statistics.reduce(into: BlockStorageCounters(bytesRead: 0, bytesWritten: 0)) { total, statistics in
            func value(_ key: String) -> UInt64 { (statistics[key] as? NSNumber)?.uint64Value ?? 0 }
            total.bytesRead &+= value("Bytes (Read)")
            total.bytesWritten &+= value("Bytes (Write)")
            total.readOperations &+= value("Operations (Read)")
            total.writeOperations &+= value("Operations (Write)")
            total.readTime &+= value("Total Time (Read)")
            total.writeTime &+= value("Total Time (Write)")
        }
    }
}
