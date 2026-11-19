import Foundation

public enum WiFiBand: String, Sendable, Codable {
    case ghz2, ghz5, ghz6, unknown
}

public struct WiFiSnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let interfaceName: String
    public let isPoweredOn: Bool
    /// `nil` when macOS withholds the network name (requires Location Services).
    public let networkName: String?
    /// dBm.
    public let rssi: Int?
    /// dBm.
    public let noise: Int?
    /// Mbps.
    public let transmitRate: Double?
    public let channel: Int?
    public let band: WiFiBand
    public let channelWidthMHz: Int?
    /// e.g. `802.11ax`.
    public let phyMode: String?

    public init(
        timestamp: Date, interfaceName: String, isPoweredOn: Bool, networkName: String?, rssi: Int?, noise: Int?,
        transmitRate: Double?, channel: Int?, band: WiFiBand, channelWidthMHz: Int?, phyMode: String?
    ) {
        self.timestamp = timestamp
        self.interfaceName = interfaceName
        self.isPoweredOn = isPoweredOn
        self.networkName = networkName
        self.rssi = rssi
        self.noise = noise
        self.transmitRate = transmitRate
        self.channel = channel
        self.band = band
        self.channelWidthMHz = channelWidthMHz
        self.phyMode = phyMode
    }

    public var isAssociated: Bool { (rssi ?? 0) != 0 }

    /// Signal-to-noise ratio in dB.
    public var signalToNoise: Int? {
        guard let rssi, let noise, rssi != 0, noise != 0 else { return nil }
        return rssi - noise
    }

    /// Common RSSI bands used in Wi-Fi planning (≥ −60 excellent, ≥ −70 good, ≥ −80 fair).
    public var signalQuality: SignalQuality? {
        guard let rssi, rssi != 0 else { return nil }
        switch rssi {
        case (-60)...: return .excellent
        case (-70)...: return .good
        case (-80)...: return .fair
        default: return .poor
        }
    }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.wifi = self }

    public var readings: [Reading] {
        guard let rssi, rssi != 0 else { return [] }
        return [Reading(metric: .wifiSignal, value: Double(rssi), unit: .count, timestamp: timestamp, provenance: .system(api: "CoreWLAN"))]
    }
}

public enum SignalQuality: String, Sendable, Codable {
    case excellent, good, fair, poor
}
