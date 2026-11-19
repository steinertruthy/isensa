import Foundation

public enum ChargeState: String, Sendable, Codable {
    case discharging
    case charging
    /// Connected to power, battery full or charging paused by macOS (Optimized Charging / Charge Limit).
    case notCharging
    case charged
}

public struct PowerAdapterInfo: Sendable, Equatable {
    public let watts: Int?
    public let name: String?
    public let isWireless: Bool

    public init(watts: Int?, name: String?, isWireless: Bool) {
        self.watts = watts
        self.name = name
        self.isWireless = isWireless
    }
}

public struct BatterySnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    /// `0...1` as shown by macOS.
    public let charge: Double
    public let state: ChargeState
    public let isExternalPowerConnected: Bool
    public let cycleCount: Int?
    /// Factory capacity in mAh.
    public let designCapacity: Int?
    /// Full-charge capacity currently reported by the gas gauge, in mAh.
    public let nominalCapacity: Int?
    /// Raw full-charge capacity (`AppleRawMaxCapacity`) in mAh.
    public let rawMaxCapacity: Int?
    /// Remaining charge in mAh.
    public let remainingCapacity: Int?
    public let voltage: Double?
    /// Positive while charging, negative while discharging.
    public let amperage: Double?
    public let temperature: Double?
    /// Minutes, as estimated by macOS. `nil` while macOS is still calculating.
    public let timeToEmpty: Int?
    public let timeToFull: Int?
    /// macOS' own classification (`Good`, `Fair`, `Poor`, `Check Battery`...).
    public let systemCondition: String?
    public let adapter: PowerAdapterInfo?

    public init(
        timestamp: Date,
        charge: Double,
        state: ChargeState,
        isExternalPowerConnected: Bool,
        cycleCount: Int?,
        designCapacity: Int?,
        nominalCapacity: Int?,
        rawMaxCapacity: Int?,
        remainingCapacity: Int?,
        voltage: Double?,
        amperage: Double?,
        temperature: Double?,
        timeToEmpty: Int?,
        timeToFull: Int?,
        systemCondition: String?,
        adapter: PowerAdapterInfo?
    ) {
        self.timestamp = timestamp
        self.charge = charge
        self.state = state
        self.isExternalPowerConnected = isExternalPowerConnected
        self.cycleCount = cycleCount
        self.designCapacity = designCapacity
        self.nominalCapacity = nominalCapacity
        self.rawMaxCapacity = rawMaxCapacity
        self.remainingCapacity = remainingCapacity
        self.voltage = voltage
        self.amperage = amperage
        self.temperature = temperature
        self.timeToEmpty = timeToEmpty
        self.timeToFull = timeToFull
        self.systemCondition = systemCondition
        self.adapter = adapter
    }

    /// Derived: full-charge capacity relative to design capacity, `0...1+`.
    public var health: Double? {
        guard let designCapacity, designCapacity > 0, let full = nominalCapacity ?? rawMaxCapacity else { return nil }
        return Double(full) / Double(designCapacity)
    }

    /// Derived: battery terminal power in watts (positive = charging).
    public var power: Double? {
        guard let voltage, let amperage else { return nil }
        return voltage * amperage
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.battery = self }

    public var readings: [Reading] {
        var result = [Reading(
            metric: .batteryCharge, value: charge, unit: .fraction,
            timestamp: timestamp, provenance: .system(api: "IOPowerSources")
        )]
        if let power {
            result.append(Reading(
                metric: .batteryPower, value: power, unit: .watts,
                timestamp: timestamp, provenance: .derived(method: "voltage × amperage")
            ))
        }
        if let temperature {
            result.append(Reading(
                metric: .batteryTemperature, value: temperature, unit: .celsius,
                timestamp: timestamp, provenance: .hardware(source: "AppleSmartBattery")
            ))
        }
        return result
    }
}
