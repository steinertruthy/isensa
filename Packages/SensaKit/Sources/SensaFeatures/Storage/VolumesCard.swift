import SensaCore
import SensaDesign
import SwiftUI

/// Every writable volume with its format and connection, and an Eject button for removable ones.
struct VolumesCard: View {
    let volumes: [VolumeInfo]
    let formatter: MetricFormatter
    @Bindable var ejector: VolumeEjector

    var body: some View {
        Card(tr("Volumes")) {
            ForEach(Array(ejector.visible(volumes).enumerated()), id: \.element.id) { index, volume in
                if index > 0 { Divider() }
                VolumeRow(volume: volume, formatter: formatter, ejector: ejector)
            }
            if let failure = ejector.failure { EjectFailureText(failure: failure) }
        }
    }
}

/// Mounted disk images (installers left open, apps' own images), which add up quietly.
struct DiskImagesCard: View {
    let images: [VolumeInfo]
    let formatter: MetricFormatter
    @Bindable var ejector: VolumeEjector

    var body: some View {
        let visible = ejector.visible(images)
        if !visible.isEmpty {
            Card(tr("Disk images"), accessory: {
                if ejector.canEject {
                    Button(tr("Eject All")) { ejector.eject(visible) }
                        .controlSize(.small)
                        .disabled(!ejector.ejecting.isEmpty)
                        .accessibilityIdentifier("storage.images.ejectAll")
                }
            }) {
                Text(tr("%@ mounted disk images. Ejecting one does not delete its file.", formatter.integer(visible.count)))
                    .font(Typography.caption).foregroundStyle(.secondary)
                ForEach(visible) { image in
                    HStack(spacing: Spacing.medium) {
                        Label(image.name, systemImage: "opticaldiscdrive").lineLimit(1).truncationMode(.middle)
                        Spacer(minLength: Spacing.medium)
                        Text(formatter.fileBytes(image.totalCapacity)).foregroundStyle(.secondary).monospacedDigit()
                        EjectButton(volume: image, ejector: ejector)
                    }
                    .font(Typography.callout)
                }
                if let failure = ejector.failure { EjectFailureText(failure: failure) }
            }
        }
    }
}

private struct VolumeRow: View {
    let volume: VolumeInfo
    let formatter: MetricFormatter
    let ejector: VolumeEjector

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Label(volume.name, systemImage: volume.isInternal ? "internaldrive" : "externaldrive").font(Typography.body.weight(.medium))
                Spacer()
                Text(description).font(Typography.caption).foregroundStyle(.secondary)
                if volume.isEjectable { EjectButton(volume: volume, ejector: ejector) }
            }
            MeterBar(value: volume.usedFraction, tint: volume.usedFraction >= 0.9 ? .orange : Hue.storage.color)
                .accessibilityLabel(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
            Text(tr("%@ available of %@", formatter.fileBytes(volume.availableCapacity), formatter.fileBytes(volume.totalCapacity)))
                .font(Typography.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    private var description: String {
        let place = volume.isInternal ? tr("Internal") : tr("External")
        return [place, volume.connection.flatMap(StorageText.connection), volume.formatName].compactMap { $0 }.joined(separator: ", ")
    }
}

private struct EjectButton: View {
    let volume: VolumeInfo
    let ejector: VolumeEjector

    var body: some View {
        if ejector.canEject {
            if ejector.ejecting.contains(volume.id) {
                ProgressView().controlSize(.small)
            } else {
                Button { ejector.eject([volume]) } label: {
                    Image(systemName: "eject.fill")
                }
                .buttonStyle(.borderless)
                .help(tr("Eject %@", volume.name))
                .accessibilityLabel(tr("Eject %@", volume.name))
            }
        }
    }
}

private struct EjectFailureText: View {
    let failure: VolumeEjector.Failure

    var body: some View {
        Label(tr("Could not eject %@: %@", failure.name, failure.reason), systemImage: "exclamationmark.triangle")
            .font(Typography.caption).foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Ejects volumes one at a time and hides them as soon as macOS confirms, without waiting for
/// the next volume refresh.
@MainActor @Observable
final class VolumeEjector {
    struct Failure: Equatable {
        let name: String
        let reason: String
    }

    private let action: (@Sendable (URL) async throws -> Void)?
    private(set) var ejecting: Set<String> = []
    private(set) var ejected: Set<String> = []
    private(set) var failure: Failure?

    init(action: (@Sendable (URL) async throws -> Void)?) {
        self.action = action
    }

    var canEject: Bool { action != nil }

    func visible(_ volumes: [VolumeInfo]) -> [VolumeInfo] {
        volumes.filter { !ejected.contains($0.id) }
    }

    /// Forgets volumes that are gone, so one mounted again later shows up.
    func sync(mounted: Set<String>) {
        ejected.formIntersection(mounted)
    }

    func eject(_ volumes: [VolumeInfo]) {
        guard let action else { return }
        failure = nil
        let pending = volumes.filter { !ejecting.contains($0.id) }
        ejecting.formUnion(pending.map(\.id))
        Task {
            for volume in pending {
                do {
                    try await action(URL(fileURLWithPath: volume.mountPoint))
                    ejected.insert(volume.id)
                } catch {
                    failure = Failure(name: volume.name, reason: error.localizedDescription)
                }
                ejecting.remove(volume.id)
            }
        }
    }
}
