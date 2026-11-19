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
        ScreenContainer(title: tr("Storage"), summary: summary(storage, formatter: formatter), symbol: "internaldrive", hue: .storage) {
            if let storage {
                if let root = storage.rootVolume {
                    HeroInstrument(stats: stats(storage, formatter: formatter)) {
                        GaugeInstrument(
                            fraction: root.usedFraction, hue: root.usedFraction >= 0.9 ? .thermal : .storage,
                            value: formatter.percent(root.usedFraction), caption: tr("used")
                        )
                    }
                }
                Card(tr("Volumes")) {
                    ForEach(Array(storage.volumes.enumerated()), id: \.element.id) { index, volume in
                        if index > 0 { Divider() }
                        VolumeRow(volume: volume, formatter: formatter)
                    }
                }
                if let health = storage.ssdHealth {
                    SSDHealthCard(health: health, formatter: formatter)
                }
                SeriesChartCard(
                    title: tr("Disk activity"),
                    lines: [
                        .init(metric: .diskRead, label: tr("Read"), color: Hue.storage.color),
                        .init(metric: .diskWrite, label: tr("Write"), color: .secondary)
                    ],
                    format: { formatter.rate($0) }
                )
                TechnicalDetails {
                    InfoRow(tr("Read"), value: formatter.rate(storage.readRate ?? 0))
                    InfoRow(tr("Write"), value: formatter.rate(storage.writeRate ?? 0))
                    if let health = storage.ssdHealth { SSDHealthCard.detailRows(health, formatter: formatter) }
                    InfoRow(tr("Source"), value: "URLResourceValues, IOBlockStorageDriver")
                    Text(tr("Available space includes purgeable space macOS can free automatically, as shown in Finder."))
                        .font(Typography.caption).foregroundStyle(.secondary)
                }
            } else {
                WaitingView()
            }
        }
    }

    private func stats(_ storage: StorageSnapshot, formatter: MetricFormatter) -> [Stat] {
        guard let root = storage.rootVolume else { return [] }
        return [
            Stat(tr("Available"), value: formatter.fileBytes(root.availableCapacity)),
            Stat(tr("Capacity"), value: formatter.fileBytes(root.totalCapacity)),
            Stat(tr("Read"), value: formatter.rate(storage.readRate ?? 0)),
            Stat(tr("Write"), value: formatter.rate(storage.writeRate ?? 0))
        ]
    }

    private func summary(_ storage: StorageSnapshot?, formatter: MetricFormatter) -> String {
        guard let root = storage?.rootVolume else { return tr("Reading sensors…") }
        if root.usedFraction >= 0.9 { return tr("Your startup disk is close to full.") }
        return tr("%@ available on your startup disk.", formatter.fileBytes(root.availableCapacity))
    }
}

private struct VolumeRow: View {
    let volume: VolumeInfo
    let formatter: MetricFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Label(volume.name, systemImage: volume.isInternal ? "internaldrive" : "externaldrive").font(Typography.body.weight(.medium))
                Spacer()
                Text(volume.isInternal ? tr("Internal") : tr("External")).font(Typography.caption).foregroundStyle(.secondary)
            }
            MeterBar(value: volume.usedFraction, tint: volume.usedFraction >= 0.9 ? .orange : Hue.storage.color)
                .accessibilityLabel(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
            Text(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
                .font(Typography.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xxSmall)
    }
}
