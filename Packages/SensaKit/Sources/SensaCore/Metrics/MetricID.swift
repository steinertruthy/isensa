import Foundation

/// Stable identifier of a time series (e.g. `cpu.usage`, `temp.smc.Tp01`).
///
/// String-backed so it can be persisted, exported and compared across launches
/// without coupling storage to Swift enum layouts.
public struct MetricID: RawRepresentable, Hashable, Sendable, Codable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }

    public var description: String { rawValue }

    public static func < (lhs: MetricID, rhs: MetricID) -> Bool { lhs.rawValue < rhs.rawValue }
}

public extension MetricID {
    static let cpuUsage = MetricID("cpu.usage")
    static let cpuUserUsage = MetricID("cpu.usage.user")
    static let cpuSystemUsage = MetricID("cpu.usage.system")
    static func cpuCoreUsage(_ index: Int) -> MetricID { MetricID("cpu.usage.core.\(index)") }

    static let gpuUsage = MetricID("gpu.usage")

    static let memoryUsed = MetricID("memory.used")
    static let memoryPressure = MetricID("memory.pressure")
    static let swapUsed = MetricID("memory.swap.used")

    static let batteryCharge = MetricID("battery.charge")
    static let batteryPower = MetricID("battery.power")
    static let batteryTemperature = MetricID("battery.temperature")

    static let systemPower = MetricID("power.system")

    static let cpuTemperature = MetricID("temperature.cpu")
    static let gpuTemperature = MetricID("temperature.gpu")
    static func sensor(_ id: SensorID) -> MetricID { MetricID("sensor.\(id.rawValue)") }
    static func fanSpeed(_ index: Int) -> MetricID { MetricID("fan.\(index).rpm") }

    static let diskRead = MetricID("disk.read")
    static let diskWrite = MetricID("disk.write")

    static let networkDownload = MetricID("network.download")
    static let networkUpload = MetricID("network.upload")
}
