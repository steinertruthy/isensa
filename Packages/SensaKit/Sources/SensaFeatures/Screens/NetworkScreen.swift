import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct NetworkScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let network = store.snapshot.network
        ScreenContainer(title: tr("Network"), summary: summary(network), symbol: "arrow.up.arrow.down", hue: .network) {
            if let network {
                CellGroup {
                    MetricCell(
                        title: tr("Download"),
                        symbol: "arrow.down",
                        hue: .network,
                        value: formatter.rate(network.downloadRate ?? 0),
                        caption: tr("Receiving")
                    ) {
                        SeriesSparkline(metric: .networkDownload, tint: Hue.network.color)
                    }
                    CellDivider()
                    MetricCell(title: tr("Upload"), symbol: "arrow.up", hue: .network, value: formatter.rate(network.uploadRate ?? 0), caption: tr("Sending")) {
                        SeriesSparkline(metric: .networkUpload, tint: Hue.network.color.opacity(0.7))
                    }
                }
                if let wifi = store.snapshot.wifi {
                    WiFiCard(wifi: wifi, formatter: formatter)
                }
                SeriesChartCard(
                    title: tr("Traffic"),
                    lines: [
                        .init(metric: .networkDownload, label: tr("Download"), color: Hue.network.color),
                        .init(metric: .networkUpload, label: tr("Upload"), color: .secondary)
                    ],
                    format: { formatter.rate($0) }
                )
                TechnicalDetails {
                    ForEach(addressedInterfaces(network)) { interface in
                        InfoRow(
                            "\(interface.id) (\(kindName(interface.kind)))",
                            value: (interface.ipv4Addresses + interface.ipv6Addresses).joined(separator: "\n")
                        )
                    }
                    if let wifi = store.snapshot.wifi, wifi.isAssociated { WiFiCard.detailRows(wifi) }
                    InfoRow(tr("Source"), value: "sysctl NET_RT_IFLIST2, getifaddrs")
                    Text(Copy.networkCountersNote).font(Typography.caption).foregroundStyle(.secondary)
                }
            } else {
                WaitingView()
            }
        }
    }

    private func summary(_ network: NetworkSnapshot?) -> String {
        guard let network else { return tr("Reading sensors…") }
        guard let primary = network.primaryInterface else { return tr("No active network connection.") }
        return tr("Connected via %@.", kindName(primary.kind))
    }

    private func addressedInterfaces(_ network: NetworkSnapshot) -> [NetworkInterfaceInfo] {
        network.interfaces.filter { interface in
            interface.isActive && interface.kind != .loopback && !(interface.ipv4Addresses.isEmpty && interface.ipv6Addresses.isEmpty)
        }
    }

    private func kindName(_ kind: NetworkInterfaceKind) -> String {
        switch kind {
        case .wifi: tr("Wi-Fi")
        case .ethernet: tr("Ethernet")
        case .cellular: tr("Cellular")
        case .loopback: tr("Loopback")
        case .other: tr("Other")
        }
    }
}
