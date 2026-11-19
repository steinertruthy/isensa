import SensaCore
import SensaDesign
import SwiftUI

/// Top processes by CPU or memory. Read-only; Sensa never terminates processes.
struct ProcessListCard: View {
    enum Ranking { case cpu, memory }

    let title: String
    let processes: [ProcessUsage]
    let ranking: Ranking
    let inaccessibleCount: Int
    let formatter: MetricFormatter

    var body: some View {
        Card(title, symbol: "list.number") {
            if processes.isEmpty {
                WaitingView(message: tr("Collecting data…")).frame(height: 80)
            } else {
                VStack(spacing: Spacing.xSmall) {
                    ForEach(processes) { process in
                        HStack(spacing: Spacing.medium) {
                            Text(process.name).lineLimit(1).truncationMode(.middle)
                            Spacer(minLength: Spacing.medium)
                            Text(primaryValue(process)).monospacedDigit().frame(minWidth: 70, alignment: .trailing)
                            Text(secondaryValue(process)).monospacedDigit().foregroundStyle(.secondary).frame(minWidth: 70, alignment: .trailing)
                        }
                        .font(Typography.callout)
                        .padding(.vertical, Spacing.xxSmall)
                        .accessibilityElement(children: .combine)
                        .help(tr("Process %@", "\(process.id)"))
                    }
                }
            }
            if inaccessibleCount > 0 {
                Text(tr("%@ system processes belong to other users and are not included.", formatter.integer(inaccessibleCount)))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func primaryValue(_ process: ProcessUsage) -> String {
        ranking == .cpu ? formatter.percent(process.cpu, fractionDigits: 1) : formatter.bytes(process.memory)
    }

    private func secondaryValue(_ process: ProcessUsage) -> String {
        ranking == .cpu ? formatter.bytes(process.memory) : formatter.percent(process.cpu, fractionDigits: 1)
    }
}
