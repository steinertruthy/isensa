import iSensaCore
import iSensaDesign
import SwiftUI

/// Operations per second and average time per operation: shows when the disk is the bottleneck
/// even while little data moves (many small reads, a busy external drive).
struct DiskPerformanceCard: View {
    let activity: DiskOperations?
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Performance")) {
            Grid(alignment: .leading, horizontalSpacing: Spacing.xLarge, verticalSpacing: Spacing.small) {
                GridRow {
                    Text("")
                    header(tr("Read"))
                    header(tr("Write"))
                }
                GridRow {
                    Text(tr("Operations")).foregroundStyle(.secondary)
                    value(activity.map { formatter.operations($0.readOperations) })
                    value(activity.map { formatter.operations($0.writeOperations) })
                }
                GridRow {
                    Text(tr("Latency")).foregroundStyle(.secondary)
                    value(activity.map { $0.readLatency.map(formatter.latency) ?? tr("Idle") })
                    value(activity.map { $0.writeLatency.map(formatter.latency) ?? tr("Idle") })
                }
            }
            .font(Typography.callout)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("storage.performance")
            Text(Copy.latencyExplanation)
                .font(Typography.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func header(_ text: String) -> some View {
        Text(text).font(Typography.caption).foregroundStyle(.secondary).gridColumnAlignment(.trailing)
    }

    private func value(_ text: String?) -> some View {
        Text(text ?? "–").monospacedDigit().frame(minWidth: 90, alignment: .trailing)
    }
}
