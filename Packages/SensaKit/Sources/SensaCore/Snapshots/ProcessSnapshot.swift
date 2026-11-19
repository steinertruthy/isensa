import Foundation

public struct ProcessUsage: Sendable, Equatable, Identifiable {
    public let id: Int32
    public let name: String
    /// CPU time used per second of wall time; 1.0 = one full core (like Activity Monitor's 100 %).
    public let cpu: Double
    /// Physical footprint in bytes (Activity Monitor's "Memory").
    public let memory: UInt64
    /// Bytes per second read from and written to storage over the last interval.
    public let diskRead: Double
    public let diskWrite: Double

    public init(id: Int32, name: String, cpu: Double, memory: UInt64, diskRead: Double = 0, diskWrite: Double = 0) {
        self.id = id
        self.name = name
        self.cpu = cpu
        self.memory = memory
        self.diskRead = diskRead
        self.diskWrite = diskWrite
    }

    public var diskTotal: Double { diskRead + diskWrite }
}

public struct ProcessSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let topByCPU: [ProcessUsage]
    public let topByMemory: [ProcessUsage]
    /// Processes with storage activity in the last interval, busiest first.
    public let topByDisk: [ProcessUsage]
    public let processCount: Int
    /// Processes owned by other users (e.g. root) whose usage macOS does not expose without privileges.
    public let inaccessibleCount: Int

    public init(
        timestamp: Date, topByCPU: [ProcessUsage], topByMemory: [ProcessUsage], processCount: Int, inaccessibleCount: Int,
        topByDisk: [ProcessUsage] = []
    ) {
        self.timestamp = timestamp
        self.topByCPU = topByCPU
        self.topByMemory = topByMemory
        self.topByDisk = topByDisk
        self.processCount = processCount
        self.inaccessibleCount = inaccessibleCount
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.processes = self }
    public var readings: [Reading] { [] }
}
