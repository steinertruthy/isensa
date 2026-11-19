import iSensaCore
import iSensaDesign
import SwiftUI

/// Frequency and activity of processor clusters (derived from IOReport residency).
struct ClusterActivityCard: View {
    let clusters: [ClusterActivity]
    let hue: Hue
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Clock speed"), accessory: { ProvenanceTag(tr("Derived")) }) {
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                ForEach(clusters) { cluster in
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(Self.name(cluster.kind)).font(Typography.caption).foregroundStyle(.secondary)
                        MetricText(cluster.averageFrequency.map { Self.megahertz($0, formatter) } ?? "–", size: .medium)
                        if let maximum = cluster.maximumFrequency, let average = cluster.averageFrequency {
                            MeterBar(value: average / maximum, tint: cluster.kind == .efficiency ? hue.color.opacity(0.6) : hue.color)
                                .accessibilityLabel(tr("Share of maximum clock speed"))
                            Text(tr("of %@, active %@ of the time", Self.megahertz(maximum, formatter), formatter.percent(cluster.activeResidency)))
                                .font(Typography.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            Text(tr("Average speed while active, from the time spent at each operating point."))
                .font(Typography.caption).foregroundStyle(.secondary)
        }
    }

    static func name(_ kind: ClusterActivity.Kind) -> String {
        switch kind {
        case .efficiency: tr("Efficiency cores")
        case .performance: tr("Performance cores")
        case .gpu: tr("GPU")
        }
    }

    static func megahertz(_ value: Double, _ formatter: MetricFormatter) -> String {
        value >= 1_000 ? "\(formatter.number(value / 1_000, fractionDigits: 2)) GHz" : "\(formatter.number(value)) MHz"
    }
}

/// Power per SoC component, with the whole-system figure when the SMC reports it.
struct PowerRailsCard: View {
    let power: PowerSnapshot
    let systemPower: Double?
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Power by component"), accessory: { ProvenanceTag(tr("Derived")) }) {
            ForEach(PowerRail.allCases, id: \.self) { rail in
                if let watts = power.rails[rail] {
                    InfoRow(Self.name(rail), value: formatter.watts(watts, fractionDigits: 2))
                }
            }
            if let systemPower {
                Divider()
                InfoRow(tr("Whole system"), value: formatter.watts(systemPower), help: tr("Includes display, SSD and everything else, as reported by the SMC."))
            }
        }
    }

    static func name(_ rail: PowerRail) -> String {
        switch rail {
        case .cpu: tr("CPU")
        case .gpu: tr("GPU")
        case .neuralEngine: tr("Neural Engine")
        case .memory: tr("Memory (DRAM)")
        }
    }
}
