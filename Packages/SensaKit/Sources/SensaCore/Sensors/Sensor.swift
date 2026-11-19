import Foundation

/// Interface a sensor is read through.
public enum SensorSource: String, Sendable, Codable, Hashable {
    case smc
    case hid
    case battery
}

/// Unique and stable sensor identifier: source + the original technical key.
public struct SensorID: Hashable, Sendable, Codable, Comparable {
    public let source: SensorSource
    /// Original key as exposed by the system (`Tp01`, `PMU tdie1`...). Never rewritten.
    public let key: String

    public init(source: SensorSource, key: String) {
        self.source = source
        self.key = key
    }

    public var rawValue: String { "\(source.rawValue).\(key)" }

    public static func < (lhs: SensorID, rhs: SensorID) -> Bool { lhs.rawValue < rhs.rawValue }
}

public enum SensorKind: String, Sendable, Codable, Hashable {
    case temperature, fan, power, voltage, current
}

public enum ComponentGroup: String, Sendable, Codable, Hashable, CaseIterable {
    case cpu, gpu, memory, storage, battery, power, system, unknown
}

/// How confident we are about what a sensor measures.
public enum SensorIdentification: Sendable, Hashable, Codable {
    /// Mapping validated on the listed model identifiers.
    case verified(models: [String])
    /// Mapping from community knowledge or self-descriptive names, not validated on this model.
    case inferred
    /// Nothing reliable is known — show the technical key only.
    case unknown
}

public struct Sensor: Sendable, Hashable, Identifiable {
    public let id: SensorID
    public let kind: SensorKind
    public let group: ComponentGroup
    /// Human name when identification is known; `nil` for unknown sensors.
    public let name: String?
    public let identification: SensorIdentification

    public init(id: SensorID, kind: SensorKind, group: ComponentGroup, name: String?, identification: SensorIdentification) {
        self.id = id
        self.kind = kind
        self.group = group
        self.name = name
        self.identification = identification
    }

    public var unit: MetricUnit {
        switch kind {
        case .temperature: .celsius
        case .fan: .rpm
        case .power: .watts
        case .voltage: .volts
        case .current: .amperes
        }
    }
}

public struct SensorReading: Sendable, Hashable, Identifiable {
    public let sensor: Sensor
    public let value: Double

    public init(sensor: Sensor, value: Double) {
        self.sensor = sensor
        self.value = value
    }

    public var id: SensorID { sensor.id }
}
