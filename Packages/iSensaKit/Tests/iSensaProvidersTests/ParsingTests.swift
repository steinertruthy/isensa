import Foundation
import IOKit.ps
@testable import iSensaProviders
import iSensaCore
import iSensaHardware
import Testing

@Suite("Provider parsing")
struct ParsingTests {
    private let now = Date(timeIntervalSince1970: 0)

    @Test func batteryFromRealWorldDictionaries() {
        // Values captured from Mac15,6 (ioreg AppleSmartBattery), discharging.
        let powerSource: [String: Any] = [
            kIOPSCurrentCapacityKey: 73, kIOPSMaxCapacityKey: 100, kIOPSIsChargingKey: false,
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue, kIOPSTimeToEmptyKey: 245,
            kIOPSBatteryHealthKey: "Check Battery", "BatteryHealthCondition": ""
        ]
        let registry: [String: Any] = [
            "CycleCount": 246, "DesignCapacity": 6_249, "NominalChargeCapacity": 5_752,
            "AppleRawMaxCapacity": 5_600, "Voltage": 12_119, "Amperage": NSNumber(value: Int64(-464)), "Temperature": 3_083
        ]
        let battery = BatteryProvider.parse(powerSource: powerSource, registry: registry, adapter: nil, timestamp: now)
        #expect(battery.charge == 0.73)
        #expect(battery.state == .discharging)
        #expect(battery.cycleCount == 246)
        #expect(battery.amperage == -0.464)
        #expect(battery.temperature == 30.83)
        #expect(battery.timeToEmpty == 245)
        #expect(battery.adapter == nil)
        #expect(battery.systemCondition == "Normal", "Legacy BatteryHealth must not override BatteryHealthCondition")
        #expect(abs((battery.health ?? 0) - 5_752.0 / 6_249.0) < 1e-9)
    }

    @Test func batteryServiceConditionIsReported() {
        let powerSource: [String: Any] = [kIOPSCurrentCapacityKey: 50, "BatteryHealthCondition": "Service Recommended"]
        let battery = BatteryProvider.parse(powerSource: powerSource, registry: [:], adapter: nil, timestamp: now)
        #expect(battery.systemCondition == "Service Recommended")
        #expect(BatteryProvider.condition(from: [:]) == nil)
    }

    @Test func batteryCalculatingTimeIsNil() {
        let powerSource: [String: Any] = [
            kIOPSCurrentCapacityKey: 50, kIOPSIsChargingKey: true,
            kIOPSPowerSourceStateKey: kIOPSACPowerValue, kIOPSTimeToFullChargeKey: -1
        ]
        let battery = BatteryProvider.parse(powerSource: powerSource, registry: [:], adapter: ["Watts": 96], timestamp: now)
        #expect(battery.state == .charging)
        #expect(battery.timeToFull == nil)
        #expect(battery.adapter?.watts == 96)
    }

    @Test func memoryAppMemoryExcludesPurgeable() {
        let vm = VMStatistics(
            pageSize: 1,
            free: 10,
            active: 0,
            inactive: 0,
            speculative: 0,
            wired: 20,
            compressed: 5,
            purgeable: 3,
            external: 7,
            internalPages: 33
        )
        let kernel = MemoryProvider.KernelMemoryState(swapUsed: 1, swapTotal: 2, pressureLevel: 2, availableLevel: 0.4)
        let memory = MemoryProvider.snapshot(vm: vm, total: 100, kernel: kernel, timestamp: now)
        #expect(memory.app == 30)
        #expect(memory.cached == 10)
        #expect(memory.used == 55)
        #expect(memory.pressure == .warning)
    }

    @Test func gpuParsing() throws {
        let properties: [String: Any] = [
            "model": "Apple M3 Pro", "gpu-core-count": 14,
            "PerformanceStatistics": ["Device Utilization %": 13, "Renderer Utilization %": 10, "Tiler Utilization %": 4]
        ]
        let gpu = try #require(GPUProvider.parse(properties, timestamp: now))
        #expect(gpu.deviceUtilization == 0.13)
        #expect(gpu.coreCount == 14)
        #expect(GPUProvider.parse(["model": "x"], timestamp: now) == nil)
    }

    @Test func rateCalculatorToleratesResets() throws {
        let rates = try #require(RateCalculator.rates(from: (100, 500), to: (300, 100), over: 2))
        #expect(rates.first == 100)
        #expect(rates.second == 0)
        #expect(RateCalculator.rates(from: (0, 0), to: (1, 1), over: 0) == nil)
    }

    @Test func profileFromFacts() {
        let facts = HardwareFacts(
            modelIdentifier: "Mac15,6", marketingName: "MacBook Pro (14-inch, Nov 2023)", computerName: nil,
            brandString: "Apple M3 Pro", isARM64: true, physicalCores: 11, logicalCores: 11,
            performanceLevels: 2, perfLevel0Cores: 5, perfLevel1Cores: 6, gpuCoreCount: 14,
            memory: 18 << 30, operatingSystem: "26.6", hasBattery: true, fanCount: 2
        )
        let profile = HardwareDiscovery.profile(from: facts)
        #expect(profile.chipFamily == .appleSilicon(generation: 3, tier: .pro))
        #expect(profile.cpu.performanceCores == 5)
        #expect(profile.cpu.efficiencyCores == 6)
        #expect(profile.isLaptop)
        let capabilities = ProductionProviders.staticCapabilities(for: profile)
        // Control goes through undocumented SMC keys and the user-installed helper.
        #expect(capabilities[.fanControl] == .experimental(.privateInterface))
    }

    @Test func fanlessDesktopHasNoFanOrBatteryFeatures() {
        let facts = HardwareFacts(
            modelIdentifier: "Mac14,3", brandString: "Apple M2", isARM64: true, physicalCores: 8, logicalCores: 8,
            performanceLevels: 2, perfLevel0Cores: 4, perfLevel1Cores: 4, operatingSystem: "26", hasBattery: false, fanCount: 0
        )
        let capabilities = ProductionProviders.staticCapabilities(for: HardwareDiscovery.profile(from: facts))
        #expect(capabilities[.battery] == .unavailable)
        #expect(capabilities[.fans] == .unavailable)
        #expect(capabilities[.fanControl] == .unavailable)
    }
}
