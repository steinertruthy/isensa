import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct StorageScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let storage = store.snapshot.storage
        ScreenContainer(title: tr("Storage"), summary: summary(storage, formatter: formatter)) {
            if let storage {
                ForEach(storage.volumes) { volume in
                    Card(volume.name, symbol: volume.isInternal ? "internaldrive" : "externaldrive", accessory: {
                        Text(volume.isInternal ? tr("Internal") : tr("External")).font(Typography.caption).foregroundStyle(.secondary)
                    }) {
                        SegmentedMeter(segments: [
                            .init(
                                id: "used",
                                label: tr("Used"),
                                value: Double(volume.usedCapacity),
                                color: volume.usedFraction >= 0.9 ? .orange : .blue,
                                detail: formatter.fileBytes(volume.usedCapacity)
                            ),
                            .init(
                                id: "free",
                                label: tr("Available"),
                                value: 0,
                                color: .secondary.opacity(0.3),
                                detail: formatter.fileBytes(volume.availableCapacity)
                            )
                        ], total: Double(volume.totalCapacity))
                        Text(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
                            .font(Typography.caption).foregroundStyle(.secondary)
                    }
                }
                SeriesChartCard(
                    title: tr("Disk activity"), symbol: "chart.xyaxis.line",
                    lines: [.init(metric: .diskRead, label: tr("Read"), color: .green), .init(metric: .diskWrite, label: tr("Write"), color: .indigo)],
                    transform: { $0 / 1_048_576 }, format: { "\(formatter.number($0, fractionDigits: 1)) MB/s" }
                )
                TechnicalDetails {
                    InfoRow(tr("Read"), value: formatter.rate(storage.readRate ?? 0))
                    InfoRow(tr("Write"), value: formatter.rate(storage.writeRate ?? 0))
                    ForEach(storage.volumes) { volume in
                        InfoRow(volume.name, value: volume.mountPoint)
                    }
                    InfoRow(tr("Source"), value: "URLResourceValues · IOBlockStorageDriver")
                    Text(tr("Available space includes purgeable space macOS can free automatically, as shown in Finder."))
                        .font(Typography.caption).foregroundStyle(.secondary)
                }
            } else {
                WaitingView()
            }
        }
    }

    private func summary(_ storage: StorageSnapshot?, formatter: MetricFormatter) -> String {
        guard let root = storage?.rootVolume else { return tr("Reading sensors…") }
        if root.usedFraction >= 0.9 { return tr("Your startup disk is close to full.") }
        return tr("%@ available on your startup disk.", formatter.fileBytes(root.availableCapacity))
    }
}
