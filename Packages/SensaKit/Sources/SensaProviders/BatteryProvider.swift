import Foundation
import IOKit.ps
import SensaCore
import SensaHardware

/// Battery state from IOPowerSources (what macOS displays) enriched with the gas gauge's
/// raw values from the `AppleSmartBattery` registry entry.
public struct BatteryProvider: MetricProvider {
    public let id = "battery"
    public let feature = Feature.battery
    public let tier = SamplingTier.slow

    public init() {}

    public func probe() async -> CapabilityState {
        PowerSources.internalBattery() == nil ? .unavailable : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        guard let powerSource = PowerSources.internalBattery() else { throw ProviderError.readFailed("IOPowerSources") }
        return Self.parse(
            powerSource: powerSource,
            registry: IORegistry.properties(ofServiceNamed: "AppleSmartBattery") ?? [:],
            adapter: PowerSources.externalAdapterDetails(),
            timestamp: Date()
        )
    }

    /// macOS' service verdict. `BatteryHealthCondition` is authoritative (empty = normal, as in
    /// System Information). The legacy `BatteryHealth` key is ignored: on Mac15,6 / macOS 26 it
    /// reports "Check Battery" while System Information reports Condition: Normal.
    static func condition(from powerSource: [String: Any]) -> String? {
        guard let condition = powerSource["BatteryHealthCondition"] as? String else { return nil }
        return condition.isEmpty ? "Normal" : condition
    }

    static func parse(powerSource: [String: Any], registry: [String: Any], adapter: [String: Any]?, timestamp: Date) -> BatterySnapshot {
        func int(_ dictionary: [String: Any], _ key: String) -> Int? { (dictionary[key] as? NSNumber)?.intValue }
        func bool(_ dictionary: [String: Any], _ key: String) -> Bool? { (dictionary[key] as? NSNumber)?.boolValue }

        let current = int(powerSource, kIOPSCurrentCapacityKey) ?? 0
        let maximum = max(int(powerSource, kIOPSMaxCapacityKey) ?? 100, 1)
        let charge = min(max(Double(current) / Double(maximum), 0), 1)

        let onAC = (powerSource[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
            || bool(registry, "ExternalConnected") == true
        let isCharging = bool(powerSource, kIOPSIsChargingKey) ?? bool(registry, "IsCharging") ?? false
        let isCharged = bool(powerSource, kIOPSIsChargedKey) ?? bool(registry, "FullyCharged") ?? false
        let state: ChargeState = if isCharging { .charging } else if !onAC { .discharging } else if isCharged { .charged } else { .notCharging }

        // IOPS uses -1 while macOS is still estimating; the registry uses 65535.
        func minutes(_ value: Int?) -> Int? { value.flatMap { $0 >= 0 && $0 < 65_535 ? $0 : nil } }

        let adapterInfo: PowerAdapterInfo? = onAC ? adapter.map {
            PowerAdapterInfo(
                watts: int($0, kIOPSPowerAdapterWattsKey),
                name: $0["Name"] as? String,
                isWireless: bool($0, "IsWireless") ?? false
            )
        } : nil

        return BatterySnapshot(
            timestamp: timestamp,
            charge: charge,
            state: state,
            isExternalPowerConnected: onAC,
            cycleCount: int(registry, "CycleCount"),
            designCapacity: int(registry, "DesignCapacity"),
            nominalCapacity: int(registry, "NominalChargeCapacity"),
            rawMaxCapacity: int(registry, "AppleRawMaxCapacity"),
            remainingCapacity: int(registry, "AppleRawCurrentCapacity"),
            voltage: int(registry, "Voltage").map { Double($0) / 1000 },
            amperage: (registry["InstantAmperage"] as? NSNumber ?? registry["Amperage"] as? NSNumber).map { Double($0.int64Value) / 1000 },
            temperature: int(registry, "Temperature").map { Double($0) / 100 },
            timeToEmpty: state == .discharging ? minutes(int(powerSource, kIOPSTimeToEmptyKey)) : nil,
            timeToFull: state == .charging ? minutes(int(powerSource, kIOPSTimeToFullChargeKey)) : nil,
            systemCondition: condition(from: powerSource),
            adapter: adapterInfo
        )
    }
}
