import iSensaCore
import iSensaDesign
import iSensaInsights
import iSensaMonitoring
import SwiftUI

/// The overview: greeting, the Pulse, and three grouped surfaces of metrics.
struct DashboardView: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Binding var selection: Destination?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.section) {
                HStack(alignment: .center) {
                    GreetingHeader()
                    Spacer(minLength: Spacing.large)
                    DeviceSummary(profile: store.profile, isDemo: store.isDemo)
                }
                PulseHero(health: health)
                ForEach(DashboardModel.groups(
                    store: store, formatter: settings.formatter, hidden: settings.hiddenDashboardCells, fanDisplay: settings.fanSpeedDisplay
                )) { group in
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(group.title).font(Typography.headline).padding(.horizontal, Spacing.xSmall)
                            .accessibilityAddTraits(.isHeader)
                        CellGroup {
                            ForEach(Array(group.cells.enumerated()), id: \.element.id) { index, cell in
                                if index > 0 { CellDivider() }
                                MetricCell(
                                    title: cell.title, symbol: cell.symbol, hue: cell.hue, value: cell.value,
                                    caption: cell.caption, level: cell.level, action: { selection = cell.destination }
                                ) {
                                    SeriesSparkline(metric: cell.metric, range: cell.range, tint: cell.hue.color)
                                }
                                .accessibilityIdentifier("tile.\(cell.kind.rawValue)")
                            }
                        }
                    }
                }
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: 1_040, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var health: SystemHealth? {
        store.snapshot == SystemSnapshot() ? nil : HealthEvaluator().evaluate(store.snapshot)
    }
}

private struct DeviceSummary: View {
    let profile: HardwareProfile
    let isDemo: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
            if isDemo { ProvenanceTag(tr("Demo data"), symbol: "theatermasks") }
            Text(profile.computerName ?? profile.displayModelName).font(Typography.headline)
            Text(profile.displayModelName).font(Typography.caption).foregroundStyle(.secondary)
            Text(tr("%@ with %@ memory", profile.chipName, MetricFormatter().bytes(profile.physicalMemory)))
                .font(Typography.caption).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.trailing)
        .accessibilityElement(children: .combine)
    }
}
