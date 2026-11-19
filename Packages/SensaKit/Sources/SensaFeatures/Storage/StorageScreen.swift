import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct StorageScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @Environment(AppNavigation.self) private var navigation
    @State private var ejector: VolumeEjector?

    var body: some View {
        let formatter = settings.formatter
        let storage = store.snapshot.storage
        ScreenContainer(title: tr("Storage"), summary: summary(storage, formatter: formatter), symbol: "internaldrive", hue: .storage) {
            if let storage {
                let ejector = ejector ?? VolumeEjector(action: nil)
                if let root = storage.rootVolume {
                    HeroInstrument(stats: stats(storage, formatter: formatter)) {
                        GaugeInstrument(
                            fraction: root.usedFraction, hue: root.usedFraction >= 0.9 ? .thermal : .storage,
                            value: formatter.percent(root.usedFraction), caption: tr("used")
                        )
                    }
                    StorageSpaceCard(volume: root, snapshots: storage.localSnapshots, formatter: formatter)
                    if services.storage.spaceAnalysis != nil { freeUpSpaceCard(formatter: formatter) }
                    StorageTrendCard(available: root.availableCapacity, hasSSDHealth: storage.ssdHealth != nil)
                }
                activitySection(storage, formatter: formatter)
                if let health = storage.ssdHealth {
                    SSDHealthCard(health: health, formatter: formatter)
                }
                VolumesCard(volumes: storage.volumes, formatter: formatter, ejector: ejector)
                DiskImagesCard(images: storage.diskImages, formatter: formatter, ejector: ejector)
                if let container = storage.container {
                    APFSContainerCard(container: container, formatter: formatter)
                }
                SpeedTestCard(volumes: storage.volumes, formatter: formatter)
                TechnicalDetails {
                    InfoRow(tr("Read"), value: formatter.rate(storage.readRate ?? 0))
                    InfoRow(tr("Write"), value: formatter.rate(storage.writeRate ?? 0))
                    if let health = storage.ssdHealth { SSDHealthCard.detailRows(health, formatter: formatter) }
                    if let container = storage.container {
                        ForEach(container.volumes) { volume in
                            InfoRow("\(volume.name) (\(volume.id))", value: formatter.fileBytes(volume.usedCapacity))
                        }
                    }
                    InfoRow(tr("Source"), value: "URLResourceValues, IOBlockStorageDriver, diskutil, tmutil, libproc")
                }
            } else {
                WaitingView()
            }
        }
        .onAppear { if ejector == nil { ejector = VolumeEjector(action: services.storage.eject) } }
        .onChange(of: Set((storage?.volumes ?? []).map(\.id) + (storage?.diskImages ?? []).map(\.id))) { _, mounted in
            ejector?.sync(mounted: mounted)
        }
    }

    private func freeUpSpaceCard(formatter: MetricFormatter) -> some View {
        Card {
            HStack(spacing: Spacing.medium) {
                Image(systemName: "sparkles").font(.title2).foregroundStyle(Hue.storage.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("What's using space")).font(Typography.body.weight(.medium))
                    Text(tr("Find the largest folders, files and apps, and move what you no longer need to the Trash."))
                        .font(Typography.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(tr("Free Up Space…")) { navigation.storagePage = .freeUpSpace }
                    .accessibilityIdentifier("storage.freeUpSpace")
            }
        }
    }

    @ViewBuilder
    private func activitySection(_ storage: StorageSnapshot, formatter: MetricFormatter) -> some View {
        SeriesChartCard(
            title: tr("Disk activity"),
            lines: [
                .init(metric: .diskRead, label: tr("Read"), color: Hue.storage.color),
                .init(metric: .diskWrite, label: tr("Write"), color: .secondary)
            ],
            format: { formatter.rate($0) }
        )
        if let processes = store.snapshot.processes {
            ProcessListCard(
                title: tr("Activity by app"), processes: processes.topByDisk, ranking: .disk,
                inaccessibleCount: processes.inaccessibleCount, formatter: formatter,
                emptyMessage: tr("No app is reading or writing right now."), note: Copy.activityByAppNote
            )
        }
        DiskPerformanceCard(activity: storage.activity, formatter: formatter)
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
