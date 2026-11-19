import Foundation

/// Static description of the Mac, discovered once at launch.
public struct HardwareProfile: Sendable, Hashable, Codable {
    /// e.g. `Mac15,6`.
    public var modelIdentifier: String
    /// e.g. `MacBook Pro (14-inch, Nov 2023)`, when the system exposes it.
    public var marketingName: String?
    /// User-facing computer name (System Settings › General › Sharing).
    public var computerName: String?
    /// e.g. `Apple M3 Pro`.
    public var chipName: String
    public var chipFamily: ChipFamily
    public var architecture: CPUArchitecture
    public var cpu: CPUTopology
    public var gpuCoreCount: Int?
    public var physicalMemory: UInt64
    public var operatingSystem: String
    public var hasBattery: Bool
    public var fanCount: Int

    public init(
        modelIdentifier: String,
        marketingName: String?,
        computerName: String?,
        chipName: String,
        chipFamily: ChipFamily,
        architecture: CPUArchitecture,
        cpu: CPUTopology,
        gpuCoreCount: Int?,
        physicalMemory: UInt64,
        operatingSystem: String,
        hasBattery: Bool,
        fanCount: Int
    ) {
        self.modelIdentifier = modelIdentifier
        self.marketingName = marketingName
        self.computerName = computerName
        self.chipName = chipName
        self.chipFamily = chipFamily
        self.architecture = architecture
        self.cpu = cpu
        self.gpuCoreCount = gpuCoreCount
        self.physicalMemory = physicalMemory
        self.operatingSystem = operatingSystem
        self.hasBattery = hasBattery
        self.fanCount = fanCount
    }

    /// Best available human name for the model.
    public var displayModelName: String { marketingName ?? modelIdentifier }

    public var isLaptop: Bool { hasBattery || modelIdentifier.hasPrefix("MacBook") }
}

public enum CPUArchitecture: String, Sendable, Hashable, Codable {
    case arm64, x86_64, unknown
}

/// Core layout. On Apple Silicon `performanceCores + efficiencyCores == logicalCores`.
public struct CPUTopology: Sendable, Hashable, Codable {
    public var physicalCores: Int
    public var logicalCores: Int
    public var performanceCores: Int?
    public var efficiencyCores: Int?

    public init(physicalCores: Int, logicalCores: Int, performanceCores: Int?, efficiencyCores: Int?) {
        self.physicalCores = physicalCores
        self.logicalCores = logicalCores
        self.performanceCores = performanceCores
        self.efficiencyCores = efficiencyCores
    }

    /// Kind of the logical core at `index`.
    ///
    /// On Apple Silicon the kernel numbers efficiency cores first, then performance
    /// cores (verified on M1–M3 via `hw.perflevel` and `host_processor_info` ordering).
    public func kind(ofCore index: Int) -> CoreKind {
        guard let efficiencyCores, let performanceCores,
              efficiencyCores + performanceCores == logicalCores else { return .uniform }
        return index < efficiencyCores ? .efficiency : .performance
    }
}

public enum CoreKind: String, Sendable, Hashable, Codable {
    case performance, efficiency, uniform
}
