import Foundation

public struct FanReading: Sendable, Hashable, Identifiable {
    public let id: Int
    public let currentRPM: Double
    public let minimumRPM: Double?
    public let maximumRPM: Double?
    public let targetRPM: Double?
    /// `true` when the firmware is in charge (no manual override).
    public let isAutomatic: Bool

    public init(id: Int, currentRPM: Double, minimumRPM: Double?, maximumRPM: Double?, targetRPM: Double?, isAutomatic: Bool) {
        self.id = id
        self.currentRPM = currentRPM
        self.minimumRPM = minimumRPM
        self.maximumRPM = maximumRPM
        self.targetRPM = targetRPM
        self.isAutomatic = isAutomatic
    }

    /// Position of the current speed in the known range, `0...1`.
    public var relativeSpeed: Double? {
        guard let minimumRPM, let maximumRPM, maximumRPM > minimumRPM else { return nil }
        return min(max((currentRPM - minimumRPM) / (maximumRPM - minimumRPM), 0), 1)
    }
}

/// Temperatures, fans and power rails read from hardware sensors.
public struct SensorSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let sensors: [SensorReading]
    public let fans: [FanReading]
    /// Mean of the identified CPU die sensors: the overall state, shown in the interface.
    public let cpuTemperature: Double?
    /// Hottest identified CPU die sensor: what fan control follows, since heat builds up at a spot,
    /// not on average. Noisier than the mean.
    public let cpuHottestTemperature: Double?
    public let gpuTemperature: Double?
    /// Total system power reported by the SMC, in watts.
    public let systemPower: Double?

    public init(
        timestamp: Date,
        sensors: [SensorReading],
        fans: [FanReading],
        cpuTemperature: Double?,
        cpuHottestTemperature: Double? = nil,
        gpuTemperature: Double?,
        systemPower: Double?
    ) {
        self.timestamp = timestamp
        self.sensors = sensors
        self.fans = fans
        self.cpuTemperature = cpuTemperature
        self.cpuHottestTemperature = cpuHottestTemperature
        self.gpuTemperature = gpuTemperature
        self.systemPower = systemPower
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.sensors = self }

    public var readings: [Reading] {
        let smc = Provenance.hardware(source: "SMC")
        var result: [Reading] = sensors.map {
            let provenance: Provenance = $0.sensor.id.source == .smc ? smc : .hardware(source: "HID")
            return Reading(metric: .sensor($0.id), value: $0.value, unit: $0.sensor.unit, timestamp: timestamp, provenance: provenance)
        }
        result += fans.map {
            Reading(metric: .fanSpeed($0.id), value: $0.currentRPM, unit: .rpm, timestamp: timestamp, provenance: smc)
        }
        let aggregate = Provenance.derived(method: "mean of identified die sensors")
        if let cpuTemperature {
            result.append(Reading(metric: .cpuTemperature, value: cpuTemperature, unit: .celsius, timestamp: timestamp, provenance: aggregate))
        }
        if let gpuTemperature {
            result.append(Reading(metric: .gpuTemperature, value: gpuTemperature, unit: .celsius, timestamp: timestamp, provenance: aggregate))
        }
        if let systemPower {
            result.append(Reading(metric: .systemPower, value: systemPower, unit: .watts, timestamp: timestamp, provenance: smc))
        }
        return result
    }
}
