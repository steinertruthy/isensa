import Foundation

/// A partial update produced by one provider. It knows which part of the
/// aggregate snapshot it replaces and which scalar series it feeds.
public protocol SnapshotFragment: Sendable {
    func apply(to snapshot: inout SystemSnapshot)
    /// Scalar values to record in time series (charts, history, menu bar).
    var readings: [Reading] { get }
}

/// Latest known state of every monitored domain. `nil` means "no data yet / not supported".
public struct SystemSnapshot: Sendable, Equatable {
    public var cpu: CPUSnapshot?
    public var gpu: GPUSnapshot?
    public var memory: MemorySnapshot?
    public var battery: BatterySnapshot?
    public var thermal: ThermalSnapshot?
    public var sensors: SensorSnapshot?
    public var storage: StorageSnapshot?
    public var network: NetworkSnapshot?
    public var performance: PerformanceSnapshot?
    public var power: PowerSnapshot?
    public var processes: ProcessSnapshot?
    public var wifi: WiFiSnapshot?

    public init() {}
}
