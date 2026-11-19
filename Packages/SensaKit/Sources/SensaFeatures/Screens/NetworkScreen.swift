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
        ScreenContainer(title: tr("Network"), summary: summary(network)) {
            if let network {
                HStack(spacing: Spacing.large) {
                    MetricTile(title: tr("Download"), symbol: "arrow.down.circle", value: formatter.rate(network.downloadRate ?? 0), caption: tr("Receiving")) {
                        SeriesSparkline(metric: .networkDownload, tint: .cyan)
                    }
                    MetricTile(title: tr("Upload"), symbol: "arrow.up.circle", value: formatter.rate(network.uploadRate ?? 0), caption: tr("Sending")) {
                        SeriesSparkline(metric: .networkUpload, tint: .pink)
                    }
                }
                SeriesChartCard(
                    title: tr("Traffic"), symbol: "chart.xyaxis.line",
                    lines: [
                        .init(metric: .networkDownload, label: tr("Download"), color: .cyan),
                        .init(metric: .networkUpload, label: tr("Upload"), color: .pink)
                    ],
                    transform: { $0 / 1_048_576 }, format: { "\(formatter.number($0, fractionDigits: 1)) MB/s" }
                )
                TechnicalDetails {
                    ForEach(addressedInterfaces(network)) { interface in
                        InfoRow(
                            "\(interface.id) · \(kindName(interface.kind))",
                            value: (interface.ipv4Addresses + interface.ipv6Addresses).joined(separator: "\n")
                        )
                        InfoRow(
                            tr("Received / sent since boot"),
                            value: "\(formatter.fileBytes(interface.totalReceived)) / \(formatter.fileBytes(interface.totalSent))"
                        )
                    }
                    InfoRow(tr("Source"), value: "sysctl NET_RT_IFLIST2 · getifaddrs")
                    Text(tr("Sensa only reads byte counters. It never inspects your traffic."))
                        .font(Typography.caption).foregroundStyle(.secondary)
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
