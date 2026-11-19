import SensaCore
import SensaDesign
import SwiftUI

/// How the startup disk is divided: the APFS volumes that share one pool of space, with
/// FileVault's state and the space taken by swap.
struct APFSContainerCard: View {
    let container: APFSContainerInfo
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Startup disk structure"), accessory: { fileVaultBadge }) {
            SegmentedMeter(
                segments: segments,
                total: Double(container.capacity)
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("storage.container")
            Text(Copy.containerExplanation)
                .font(Typography.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var fileVaultBadge: some View {
        if let isOn = container.isFileVaultOn {
            StatusBadge(level: isOn ? .normal : .attention, text: isOn ? tr("FileVault on") : tr("FileVault off"))
                .help(isOn
                    ? tr("The data on this disk is encrypted with your login password.")
                    : tr("Turn on FileVault in System Settings › Privacy & Security to encrypt your data."))
        }
    }

    private var segments: [SegmentedMeter.Segment] {
        // Small volumes (Preboot, Recovery, Update) are grouped so the bar stays readable.
        let order: [APFSContainerInfo.Role] = [.data, .system, .virtualMemory]
        var result = order.compactMap { role -> SegmentedMeter.Segment? in
            let used = container.volumes.filter { $0.role == role }.reduce(0) { $0 + $1.usedCapacity }
            guard used > 0 else { return nil }
            return .init(id: Self.name(role), label: Self.name(role), value: Double(used), color: Self.color(role), detail: formatter.fileBytes(used))
        }
        let rest = container.volumes.filter { !order.contains($0.role) }.reduce(0) { $0 + $1.usedCapacity }
        if rest > 0 {
            result.append(.init(id: "other", label: tr("Startup and recovery"), value: Double(rest), color: Hue.neutral.color,
                                detail: formatter.fileBytes(rest)))
        }
        result.append(.init(id: "free", label: tr("Free"), value: Double(container.freeCapacity), color: Color.secondary.opacity(0.25),
                            detail: formatter.fileBytes(container.freeCapacity)))
        return result
    }

    static func name(_ role: APFSContainerInfo.Role) -> String {
        switch role {
        case .data: tr("Your data")
        case .system: tr("macOS")
        case .virtualMemory: tr("Swap and sleep image")
        case .preboot: tr("Startup files")
        case .recovery: tr("Recovery")
        case .update: tr("macOS updates")
        case let .other(name): name
        }
    }

    private static func color(_ role: APFSContainerInfo.Role) -> Color {
        switch role {
        case .data: Hue.storage.color
        case .system: Hue.cpu.color
        case .virtualMemory: Hue.memory.color
        default: Hue.neutral.color
        }
    }
}
