import Foundation
import iSensaCore

/// ⚠️ DEMONSTRATION ENVIRONMENT — fictional hardware profiles used to exercise
/// capability-driven UI (fanless laptop, desktop without battery…) without real hardware.
public enum DemoEnvironment {
    public enum Variant: String, Sendable, CaseIterable {
        /// Laptop with battery and two fans.
        case laptopWithFans
        /// Fanless laptop.
        case fanlessLaptop
        /// Desktop with one fan and no battery.
        case desktop
    }

    public static func profile(_ variant: Variant) -> HardwareProfile {
        let hasBattery = variant != .desktop
        let fans = switch variant {
        case .laptopWithFans: 2
        case .fanlessLaptop: 0
        case .desktop: 1
        }
        let name = switch variant {
        case .laptopWithFans: "Demo Laptop"
        case .fanlessLaptop: "Demo Fanless Laptop"
        case .desktop: "Demo Desktop"
        }
        return HardwareProfile(
            modelIdentifier: "Demo",
            marketingName: name,
            computerName: "Demo Mac",
            chipName: "Demo Chip",
            chipFamily: .unknown,
            architecture: .arm64,
            cpu: CPUTopology(physicalCores: 10, logicalCores: 10, performanceCores: 6, efficiencyCores: 4),
            gpuCoreCount: 16,
            physicalMemory: 16 << 30,
            operatingSystem: "Demo",
            hasBattery: hasBattery,
            fanCount: fans
        )
    }

    public static func staticCapabilities(for profile: HardwareProfile) -> [Feature: CapabilityState] {
        [
            .battery: profile.hasBattery ? .available : .unavailable,
            .powerAdapter: profile.hasBattery ? .available : .unavailable,
            .fans: profile.fanCount > 0 ? .available : .unavailable,
            .fanControl: profile.fanCount > 0 ? .experimental(.privateInterface) : .unavailable
        ]
    }

    public static func providers(for profile: HardwareProfile) -> [any MetricProvider] {
        var providers: [any MetricProvider] = [
            cpu(profile), gpu(), memory(profile), thermal(), sensors(profile), storage(), network(),
            performance(), power(), processes(), wifi()
        ]
        if profile.hasBattery { providers.append(battery()) }
        return providers
    }

    private static func cpu(_ profile: HardwareProfile) -> any MetricProvider {
        DemoProvider(id: "demo.cpu", feature: .cpuUsage, tier: .fast) { t in
            let cores = (0..<profile.cpu.logicalCores).map { index in
                CPUSnapshot.Core(
                    id: index,
                    kind: profile.cpu.kind(ofCore: index),
                    usage: wave(t, period: 9, phase: Double(index) / 7, base: 0.3, amplitude: 0.25)
                )
            }
            let total = cores.map(\.usage).reduce(0, +) / Double(cores.count)
            return CPUSnapshot(
                timestamp: Date(),
                totalUsage: total,
                userUsage: total * 0.7,
                systemUsage: total * 0.3,
                cores: cores,
                loadAverage: [2.1, 1.8, 1.6]
            )
        }
    }

    private static func gpu() -> any MetricProvider {
        DemoProvider(id: "demo.gpu", feature: .gpuUsage, tier: .fast) { t in
            GPUSnapshot(
                timestamp: Date(), name: "Demo GPU", coreCount: 16,
                deviceUtilization: wave(t, period: 14, base: 0.25, amplitude: 0.2),
                rendererUtilization: nil, tilerUtilization: nil, memoryInUse: 1 << 30, provenance: .demo
            )
        }
    }

    private static func memory(_ profile: HardwareProfile) -> any MetricProvider {
        DemoProvider(id: "demo.memory", feature: .memory, tier: .medium) { t in
            let gib: UInt64 = 1 << 30
            return MemorySnapshot(
                timestamp: Date(), total: profile.physicalMemory,
                app: UInt64(6 + 2 * wave(t, period: 40, base: 0.5, amplitude: 0.5)) * gib,
                wired: 2 * gib, compressed: gib, cached: 4 * gib, free: gib,
                swapUsed: 0, swapTotal: 0, pressure: .normal,
                availableLevel: wave(t, period: 40, base: 0.6, amplitude: 0.1)
            )
        }
    }

    private static func thermal() -> any MetricProvider {
        DemoProvider(id: "demo.thermal", feature: .thermalState, tier: .medium) { _ in
            ThermalSnapshot(timestamp: Date(), level: .nominal, pressure: .nominal)
        }
    }

    private static func sensors(_ profile: HardwareProfile) -> any MetricProvider {
        DemoProvider(id: "demo.sensors", feature: .temperatureSensors, tier: .medium) { t in
            let cpuTemperature = 45 + 15 * wave(t, period: 30, base: 0.5, amplitude: 0.5)
            let sensors = (1...4).map { index in
                SensorReading(
                    sensor: Sensor(
                        id: SensorID(source: .smc, key: "Demo\(index)"),
                        kind: .temperature,
                        group: .cpu,
                        name: "Demo sensor \(index)",
                        identification: .unknown
                    ),
                    value: cpuTemperature + Double(index)
                )
            }
            let fans = (0..<profile.fanCount).map {
                FanReading(
                    id: $0,
                    currentRPM: 1_800 + 600 * wave(t, period: 30, base: 0.5, amplitude: 0.5),
                    minimumRPM: 1_200,
                    maximumRPM: 6_000,
                    targetRPM: nil,
                    isAutomatic: true
                )
            }
            return SensorSnapshot(
                timestamp: Date(),
                sensors: sensors,
                fans: fans,
                cpuTemperature: cpuTemperature,
                cpuHottestTemperature: cpuTemperature + 9,
                gpuTemperature: cpuTemperature - 4,
                systemPower: 8 + 10 * wave(t, period: 20, base: 0.4, amplitude: 0.3)
            )
        }
    }

    private static func performance() -> any MetricProvider {
        DemoProvider(id: "demo.performance", feature: .cpuFrequency, tier: .medium) { t in
            PerformanceSnapshot(timestamp: Date(), clusters: [
                ClusterActivity(
                    kind: .efficiency,
                    averageFrequency: 1_200 + 800 * wave(t, period: 12, base: 0.5, amplitude: 0.5),
                    maximumFrequency: 2_400,
                    activeResidency: 0.3
                ),
                ClusterActivity(
                    kind: .performance,
                    averageFrequency: 2_000 + 1_000 * wave(t, period: 9, base: 0.5, amplitude: 0.5),
                    maximumFrequency: 4_000,
                    activeResidency: 0.15
                ),
                ClusterActivity(kind: .gpu, averageFrequency: 600, maximumFrequency: 1_400, activeResidency: 0.2)
            ])
        }
    }

    private static func power() -> any MetricProvider {
        DemoProvider(id: "demo.power", feature: .powerConsumption, tier: .medium) { t in
            PowerSnapshot(timestamp: Date(), rails: [
                .cpu: 1 + 3 * wave(t, period: 9, base: 0.4, amplitude: 0.4), .gpu: 0.8, .memory: 0.4, .neuralEngine: 0
            ])
        }
    }

    private static func processes() -> any MetricProvider {
        DemoProvider(id: "demo.processes", feature: .processes, tier: .medium) { _ in
            let list = [
                ProcessUsage(id: 101, name: "Demo Browser", cpu: 0.24, memory: 1_400_000_000),
                ProcessUsage(id: 102, name: "Demo Editor", cpu: 0.11, memory: 800_000_000),
                ProcessUsage(id: 103, name: "Demo Music", cpu: 0.04, memory: 300_000_000)
            ]
            let disk = [
                ProcessUsage(id: 102, name: "Demo Editor", cpu: 0.11, memory: 800_000_000, diskRead: 120_000, diskWrite: 2_400_000),
                ProcessUsage(id: 101, name: "Demo Browser", cpu: 0.24, memory: 1_400_000_000, diskRead: 800_000, diskWrite: 350_000)
            ]
            return ProcessSnapshot(
                timestamp: Date(), topByCPU: list, topByMemory: list, processCount: 420, inaccessibleCount: 150, topByDisk: disk
            )
        }
    }

    private static func wifi() -> any MetricProvider {
        DemoProvider(id: "demo.wifi", feature: .wifiDetails, tier: .medium) { _ in
            WiFiSnapshot(
                timestamp: Date(), interfaceName: "en0", isPoweredOn: true, networkName: "Demo Network", rssi: -52, noise: -92,
                transmitRate: 1_200, channel: 36, band: .ghz5, channelWidthMHz: 80, phyMode: "802.11ax (Wi-Fi 6)"
            )
        }
    }

    private static func battery() -> any MetricProvider {
        DemoProvider(id: "demo.battery", feature: .battery, tier: .slow) { _ in
            BatterySnapshot(
                timestamp: Date(), charge: 0.82, state: .charging, isExternalPowerConnected: true,
                cycleCount: 120, designCapacity: 5_000, nominalCapacity: 4_700, rawMaxCapacity: 4_650,
                remainingCapacity: 3_850, voltage: 12.4, amperage: 1.6, temperature: 31,
                timeToEmpty: nil, timeToFull: 38, systemCondition: "Good",
                adapter: PowerAdapterInfo(watts: 70, name: "Demo Adapter", isWireless: false)
            )
        }
    }

    private static func storage() -> any MetricProvider {
        DemoProvider(id: "demo.storage", feature: .storage, tier: .medium) { t in
            StorageSnapshot(
                timestamp: Date(),
                volumes: [
                    VolumeInfo(
                        id: "demo", name: "Macintosh HD", mountPoint: "/", totalCapacity: 512_000_000_000,
                        availableCapacity: 210_000_000_000, isInternal: true, isRemovable: false, isRoot: true,
                        freeCapacity: 185_000_000_000, formatName: "APFS", connection: .appleFabric
                    ),
                    VolumeInfo(
                        id: "demo.external", name: "Demo Backup", mountPoint: "/Volumes/Demo Backup", totalCapacity: 1_000_000_000_000,
                        availableCapacity: 640_000_000_000, isInternal: false, isRemovable: true, isRoot: false,
                        freeCapacity: 640_000_000_000, isEjectable: true, formatName: "APFS", connection: .usb
                    )
                ],
                readRate: 2_000_000 * wave(t, period: 7, base: 0.3, amplitude: 0.3),
                writeRate: 1_000_000 * wave(t, period: 11, base: 0.3, amplitude: 0.3),
                diskImages: [VolumeInfo(
                    id: "demo.image", name: "Demo Installer", mountPoint: "/Volumes/Demo Installer", totalCapacity: 400_000_000,
                    availableCapacity: 20_000_000, isInternal: false, isRemovable: true, isRoot: false,
                    isEjectable: true, formatName: "Mac OS Extended", connection: .diskImage
                )],
                activity: DiskOperations(
                    readOperations: 300 * wave(t, period: 7, base: 0.5, amplitude: 0.4), writeOperations: 120,
                    readLatency: 0.000_42, writeLatency: 0.000_06
                ),
                container: APFSContainerInfo(identifier: "disk3", capacity: 494_000_000_000, freeCapacity: 185_000_000_000, volumes: [
                    .init(id: "disk3s1", name: "Macintosh HD", role: .system, usedCapacity: 12_000_000_000, isFileVaultOn: true),
                    .init(id: "disk3s5", name: "Macintosh HD - Data", role: .data, usedCapacity: 280_000_000_000, isFileVaultOn: true),
                    .init(id: "disk3s6", name: "VM", role: .virtualMemory, usedCapacity: 4_000_000_000, isFileVaultOn: false),
                    .init(id: "disk3s2", name: "Preboot", role: .preboot, usedCapacity: 8_000_000_000, isFileVaultOn: false),
                    .init(id: "disk3s3", name: "Recovery", role: .recovery, usedCapacity: 2_000_000_000, isFileVaultOn: false)
                ]),
                localSnapshots: LocalSnapshotSummary(timeMachine: 2, systemUpdate: 1, other: 0, newestTimeMachine: Date())
            )
        }
    }

    private static func network() -> any MetricProvider {
        DemoProvider(id: "demo.network", feature: .network, tier: .fast) { t in
            NetworkSnapshot(
                timestamp: Date(),
                interfaces: [NetworkInterfaceInfo(
                    id: "en0",
                    kind: .wifi,
                    isActive: true,
                    ipv4Addresses: ["192.0.2.10"],
                    ipv6Addresses: [],
                    totalReceived: 0,
                    totalSent: 0
                )],
                downloadRate: 3_000_000 * wave(t, period: 6, base: 0.4, amplitude: 0.4),
                uploadRate: 400_000 * wave(t, period: 8, base: 0.4, amplitude: 0.4)
            )
        }
    }
}
