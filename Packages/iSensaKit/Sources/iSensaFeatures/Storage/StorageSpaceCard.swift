import iSensaCore
import iSensaDesign
import SwiftUI

/// The startup disk's space as three parts — used, purgeable, free — so the gap between
/// Finder's "available" and what is actually free has an explanation.
struct StorageSpaceCard: View {
    let volume: VolumeInfo
    let snapshots: LocalSnapshotSummary?
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Space")) {
            if let free = volume.freeCapacity, let purgeable = volume.purgeableCapacity {
                SegmentedMeter(segments: [
                    .init(id: "used", label: tr("Used"), value: Double(volume.usedCapacity), color: Hue.storage.color,
                          detail: formatter.fileBytes(volume.usedCapacity)),
                    .init(id: "purgeable", label: tr("Purgeable"), value: Double(purgeable), color: Hue.storage.color.opacity(0.45),
                          detail: formatter.fileBytes(purgeable)),
                    .init(id: "free", label: tr("Free"), value: Double(free), color: Color.secondary.opacity(0.25),
                          detail: formatter.fileBytes(free))
                ], total: Double(volume.totalCapacity))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("storage.space")
                Text(Copy.purgeableExplanation)
                    .font(Typography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
            }
            if let snapshots {
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    Label(tr("Local snapshots"), systemImage: "camera.metering.matrix").font(Typography.body.weight(.medium))
                    Spacer()
                    Text(snapshotSummary(snapshots)).foregroundStyle(.secondary).monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                Text(Copy.snapshotsExplanation)
                    .font(Typography.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func snapshotSummary(_ snapshots: LocalSnapshotSummary) -> String {
        guard snapshots.total > 0 else { return tr("None") }
        var parts: [String] = []
        if snapshots.timeMachine > 0 { parts.append(tr("Time Machine: %@", formatter.integer(snapshots.timeMachine))) }
        if snapshots.systemUpdate > 0 { parts.append(tr("macOS updates: %@", formatter.integer(snapshots.systemUpdate))) }
        if snapshots.other > 0 { parts.append(tr("Other: %@", formatter.integer(snapshots.other))) }
        return ListFormatter.localizedString(byJoining: parts)
    }
}
