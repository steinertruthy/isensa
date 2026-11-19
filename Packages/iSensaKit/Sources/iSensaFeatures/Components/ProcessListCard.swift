import iSensaCore
import iSensaDesign
import SwiftUI

/// Top processes by CPU, memory or storage activity. Read-only; iSensa never terminates processes.
struct ProcessListCard: View {
    enum Ranking { case cpu, memory, disk }

    let title: String
    let processes: [ProcessUsage]
    let ranking: Ranking
    let inaccessibleCount: Int
    let formatter: MetricFormatter
    var emptyMessage: String?
    var note: String?

    var body: some View {
        Card(title) {
            if processes.isEmpty {
                if let emptyMessage {
                    Text(emptyMessage).font(Typography.callout).foregroundStyle(.secondary)
                } else {
                    WaitingView(message: tr("Collecting data…")).frame(height: 80)
                }
            } else {
                VStack(spacing: Spacing.xSmall) {
                    if ranking == .disk { header }
                    ForEach(processes) { process in
                        HStack(spacing: Spacing.medium) {
                            Text(process.name).lineLimit(1).truncationMode(.middle)
                            Spacer(minLength: Spacing.medium)
                            Text(primaryValue(process)).monospacedDigit().frame(minWidth: 80, alignment: .trailing)
                            Text(secondaryValue(process)).monospacedDigit().foregroundStyle(.secondary).frame(minWidth: 80, alignment: .trailing)
                        }
                        .font(Typography.callout)
                        .padding(.vertical, Spacing.xxSmall)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilityText(process))
                        .help(tr("Process %@", "\(process.id)"))
                    }
                }
            }
            if let note {
                Text(note).font(Typography.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else if inaccessibleCount > 0 {
                Text(tr("%@ system processes belong to other users and are not included.", formatter.integer(inaccessibleCount)))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.medium) {
            Spacer()
            Text(tr("Write")).frame(minWidth: 80, alignment: .trailing)
            Text(tr("Read")).frame(minWidth: 80, alignment: .trailing)
        }
        .font(Typography.caption).foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    private func accessibilityText(_ process: ProcessUsage) -> String {
        switch ranking {
        case .disk: tr("%@: writing %@, reading %@", process.name, formatter.rate(process.diskWrite), formatter.rate(process.diskRead))
        case .cpu, .memory: "\(process.name), \(primaryValue(process)), \(secondaryValue(process))"
        }
    }

    private func primaryValue(_ process: ProcessUsage) -> String {
        switch ranking {
        case .cpu: formatter.percent(process.cpu, fractionDigits: 1)
        case .memory: formatter.bytes(process.memory)
        case .disk: formatter.rate(process.diskWrite)
        }
    }

    private func secondaryValue(_ process: ProcessUsage) -> String {
        switch ranking {
        case .cpu: formatter.bytes(process.memory)
        case .memory: formatter.percent(process.cpu, fractionDigits: 1)
        case .disk: formatter.rate(process.diskRead)
        }
    }
}
