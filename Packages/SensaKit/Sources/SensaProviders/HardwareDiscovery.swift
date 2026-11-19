import Foundation
import SensaCore
import SensaHardware
import SensaPrivateAPI
import SystemConfiguration

/// Raw facts gathered from the system, kept separate so profile assembly is testable.
struct HardwareFacts: Sendable {
    var modelIdentifier: String?
    var marketingName: String?
    var computerName: String?
    var brandString: String?
    var isARM64: Bool
    var physicalCores: Int?
    var logicalCores: Int?
    var performanceLevels: Int?
    var perfLevel0Cores: Int?
    var perfLevel1Cores: Int?
    var gpuCoreCount: Int?
    var memory: UInt64?
    var operatingSystem: String
    var hasBattery: Bool
    var fanCount: Int
}

/// Identifies the Mac at launch from what the system actually reports — never from assumptions.
public enum HardwareDiscovery {
    public static func discover() -> HardwareProfile {
        profile(from: gatherFacts())
    }

    static func gatherFacts() -> HardwareFacts {
        let accelerator = IORegistry.properties(ofClass: "IOAccelerator").first
        let fanCount = (try? SMCConnection()).flatMap { $0.number("FNum") }.map { Int($0) } ?? 0
        return HardwareFacts(
            modelIdentifier: Sysctl.string("hw.model"),
            marketingName: IORegistry.string(fromDeviceTreeValue: IORegistry.deviceTreeProperty(path: "/product", key: "product-name")),
            computerName: SCDynamicStoreCopyComputerName(nil, nil) as String?,
            brandString: Sysctl.string("machdep.cpu.brand_string"),
            isARM64: Sysctl.int32("hw.optional.arm64") == 1,
            physicalCores: Sysctl.int("hw.physicalcpu"),
            logicalCores: Sysctl.int("hw.logicalcpu"),
            performanceLevels: Sysctl.int("hw.nperflevels"),
            perfLevel0Cores: Sysctl.int("hw.perflevel0.logicalcpu"),
            perfLevel1Cores: Sysctl.int("hw.perflevel1.logicalcpu"),
            gpuCoreCount: (accelerator?["gpu-core-count"] as? NSNumber)?.intValue,
            memory: Sysctl.uint64("hw.memsize"),
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            hasBattery: PowerSources.internalBattery() != nil,
            fanCount: max(fanCount, 0)
        )
    }

    static func profile(from facts: HardwareFacts) -> HardwareProfile {
        let logical = facts.logicalCores ?? ProcessInfo.processInfo.processorCount
        // Apple Silicon: perflevel0 = performance cores, perflevel1 = efficiency cores.
        let hasTwoLevels = (facts.performanceLevels ?? 1) >= 2
        let brand = facts.brandString ?? "Unknown processor"
        return HardwareProfile(
            modelIdentifier: facts.modelIdentifier ?? "Mac",
            marketingName: facts.marketingName,
            computerName: facts.computerName,
            chipName: brand,
            chipFamily: ChipFamily(brandString: brand),
            architecture: facts.isARM64 ? .arm64 : .x86_64,
            cpu: CPUTopology(
                physicalCores: facts.physicalCores ?? logical,
                logicalCores: logical,
                performanceCores: hasTwoLevels ? facts.perfLevel0Cores : nil,
                efficiencyCores: hasTwoLevels ? facts.perfLevel1Cores : nil
            ),
            gpuCoreCount: facts.gpuCoreCount,
            physicalMemory: facts.memory ?? ProcessInfo.processInfo.physicalMemory,
            operatingSystem: facts.operatingSystem,
            hasBattery: facts.hasBattery,
            fanCount: facts.fanCount
        )
    }
}
