import Foundation
import SensaCore
import SensaHardware

/// GPU utilisation published by the graphics driver in the I/O Registry
/// (`IOAccelerator` › `PerformanceStatistics`). Works on Apple Silicon and most Intel/AMD GPUs.
public struct GPUProvider: MetricProvider {
    public let id = "gpu.usage"
    public let feature = Feature.gpuUsage
    public let tier = SamplingTier.fast

    public init() {}

    public func probe() async -> CapabilityState {
        Self.read(timestamp: Date()) == nil ? .unsupported : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        guard let snapshot = Self.read(timestamp: Date()) else { throw ProviderError.readFailed("IOAccelerator") }
        return snapshot
    }

    static func read(timestamp: Date) -> GPUSnapshot? {
        // Prefer the accelerator reporting the highest utilisation (integrated vs discrete on Intel Macs).
        IORegistry.properties(ofClass: "IOAccelerator")
            .compactMap { parse($0, timestamp: timestamp) }
            .max { $0.deviceUtilization < $1.deviceUtilization }
    }

    static func parse(_ properties: [String: Any], timestamp: Date) -> GPUSnapshot? {
        guard let statistics = properties["PerformanceStatistics"] as? [String: Any],
              let device = (statistics["Device Utilization %"] as? NSNumber)?.doubleValue else { return nil }
        func percent(_ key: String) -> Double? { (statistics[key] as? NSNumber).map { $0.doubleValue / 100 } }
        return GPUSnapshot(
            timestamp: timestamp,
            name: properties["model"] as? String ?? "GPU",
            coreCount: (properties["gpu-core-count"] as? NSNumber)?.intValue,
            deviceUtilization: min(max(device / 100, 0), 1),
            rendererUtilization: percent("Renderer Utilization %"),
            tilerUtilization: percent("Tiler Utilization %"),
            memoryInUse: (statistics["In use system memory"] as? NSNumber)?.uint64Value,
            provenance: .system(api: "IOAccelerator.PerformanceStatistics")
        )
    }
}
