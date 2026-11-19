import Foundation

public struct ProcessUsage: Sendable, Equatable, Identifiable {
    public let id: Int32
    public let name: String
    /// CPU time used per second of wall time; 1.0 = one full core (like Activity Monitor's 100 %).
    public let cpu: Double
    /// Physical footprint in bytes (Activity Monitor's "Memory").
    public let memory: UInt64

    public init(id: Int32, name: String, cpu: Double, memory: UInt64) {
        self.id = id
        self.name = name
        self.cpu = cpu
        self.memory = memory
    }
}

public struct ProcessSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let topByCPU: [ProcessUsage]
    public let topByMemory: [ProcessUsage]
    public let processCount: Int
    /// Processes owned by other users (e.g. root) whose usage macOS does not expose without privileges.
    public let inaccessibleCount: Int

    public init(timestamp: Date, topByCPU: [ProcessUsage], topByMemory: [ProcessUsage], processCount: Int, inaccessibleCount: Int) {
        self.timestamp = timestamp
        self.topByCPU = topByCPU
        self.topByMemory = topByMemory
        self.processCount = processCount
        self.inaccessibleCount = inaccessibleCount
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.processes = self }
    public var readings: [Reading] { [] }
}
