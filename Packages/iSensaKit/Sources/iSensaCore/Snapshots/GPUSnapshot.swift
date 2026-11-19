import Foundation

public struct GPUSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let name: String
    public let coreCount: Int?
    /// `0...1` — share of time the GPU was busy (any engine).
    public let deviceUtilization: Double
    public let rendererUtilization: Double?
    public let tilerUtilization: Double?
    /// Unified memory currently used by the GPU, in bytes.
    public let memoryInUse: UInt64?
    public let provenance: Provenance

    public init(
        timestamp: Date,
        name: String,
        coreCount: Int?,
        deviceUtilization: Double,
        rendererUtilization: Double?,
        tilerUtilization: Double?,
        memoryInUse: UInt64?,
        provenance: Provenance
    ) {
        self.timestamp = timestamp
        self.name = name
        self.coreCount = coreCount
        self.deviceUtilization = deviceUtilization
        self.rendererUtilization = rendererUtilization
        self.tilerUtilization = tilerUtilization
        self.memoryInUse = memoryInUse
        self.provenance = provenance
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.gpu = self }

    public var readings: [Reading] {
        [Reading(metric: .gpuUsage, value: deviceUtilization, unit: .fraction, timestamp: timestamp, provenance: provenance)]
    }
}
