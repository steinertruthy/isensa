import CoreWLAN
import Foundation
import iSensaCore

/// Wi-Fi link details from CoreWLAN (public). macOS hides the network name unless the
/// app has Location Services permission; iSensa reports that instead of guessing.
public struct WiFiProvider: MetricProvider {
    public let id = "wifi"
    public let feature = Feature.wifiDetails
    public let tier = SamplingTier.medium
    /// Only shown in the main window and popover.
    public let minimumDemand = Demand.interactive

    public init() {}

    public func probe() async -> CapabilityState {
        CWWiFiClient.shared().interface() == nil ? .unavailable : .available
    }

    public func sample() async throws -> any SnapshotFragment {
        guard let interface = CWWiFiClient.shared().interface() else { throw ProviderError.interfaceUnavailable("CoreWLAN") }
        let channel = interface.wlanChannel()
        return WiFiSnapshot(
            timestamp: Date(),
            interfaceName: interface.interfaceName ?? "Wi-Fi",
            isPoweredOn: interface.powerOn(),
            networkName: interface.ssid(),
            rssi: interface.rssiValue(),
            noise: interface.noiseMeasurement(),
            transmitRate: interface.transmitRate() > 0 ? interface.transmitRate() : nil,
            channel: channel.map(\.channelNumber),
            band: channel.map { Self.band($0.channelBand) } ?? .unknown,
            channelWidthMHz: channel.flatMap { Self.width($0.channelWidth) },
            phyMode: Self.phyMode(interface.activePHYMode())
        )
    }

    static func band(_ band: CWChannelBand) -> WiFiBand {
        switch band {
        case .band2GHz: .ghz2
        case .band5GHz: .ghz5
        case .band6GHz: .ghz6
        default: .unknown
        }
    }

    static func width(_ width: CWChannelWidth) -> Int? {
        switch width {
        case .width20MHz: 20
        case .width40MHz: 40
        case .width80MHz: 80
        case .width160MHz: 160
        default: nil
        }
    }

    static func phyMode(_ mode: CWPHYMode) -> String? {
        switch mode {
        case .mode11a: "802.11a"
        case .mode11b: "802.11b"
        case .mode11g: "802.11g"
        case .mode11n: "802.11n (Wi-Fi 4)"
        case .mode11ac: "802.11ac (Wi-Fi 5)"
        case .mode11ax: "802.11ax (Wi-Fi 6)"
        default: nil
        }
    }
}
