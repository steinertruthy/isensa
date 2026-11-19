import SensaCore
import SensaDesign
import SwiftUI

struct WiFiCard: View {
    let wifi: WiFiSnapshot
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Wi-Fi"), accessory: {
            if let quality = wifi.signalQuality {
                StatusBadge(level: quality == .poor ? .attention : .normal, text: Self.name(quality))
            }
        }) {
            if !wifi.isPoweredOn {
                Text(tr("Wi-Fi is turned off.")).foregroundStyle(.secondary)
            } else if !wifi.isAssociated {
                Text(tr("Not connected to a Wi-Fi network.")).foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: Spacing.xLarge) {
                    metric(wifi.rssi.map { "\($0) dBm" } ?? "–", tr("Signal"))
                    metric(wifi.transmitRate.map { "\(formatter.number($0)) Mbps" } ?? "–", tr("Link speed"))
                    metric(bandText, tr("Band"))
                }
                Text(wifi.networkName.map { tr("Network: %@", $0) } ?? tr("macOS shows the network name only to apps with Location Services permission."))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
        }
    }

    /// Wi-Fi fields for the screen's technical details section.
    @ViewBuilder
    static func detailRows(_ wifi: WiFiSnapshot) -> some View {
        if let noise = wifi.noise, noise != 0 { InfoRow(tr("Noise"), value: "\(noise) dBm") }
        if let snr = wifi.signalToNoise {
            InfoRow(tr("Signal-to-noise ratio"), value: "\(snr) dB", help: tr("Higher is better; above 25 dB is a solid connection."))
        }
        if let channel = wifi.channel { InfoRow(tr("Channel"), value: "\(channel)") }
        if let width = wifi.channelWidthMHz { InfoRow(tr("Channel width"), value: "\(width) MHz") }
        if let phy = wifi.phyMode { InfoRow(tr("Standard"), value: phy) }
        InfoRow(tr("Wi-Fi interface"), value: "\(wifi.interfaceName) · CoreWLAN")
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(value).font(Typography.metricSmall).contentTransition(.numericText())
            Text(label).font(Typography.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var bandText: String {
        switch wifi.band {
        case .ghz2: "2.4 GHz"
        case .ghz5: "5 GHz"
        case .ghz6: "6 GHz"
        case .unknown: "–"
        }
    }

    static func name(_ quality: SignalQuality) -> String {
        switch quality {
        case .excellent: tr("Excellent signal")
        case .good: tr("Good signal")
        case .fair: tr("Fair signal")
        case .poor: tr("Weak signal")
        }
    }
}
