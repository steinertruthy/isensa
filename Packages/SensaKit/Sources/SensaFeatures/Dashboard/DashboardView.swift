import SensaCore
import SensaDesign
import SensaInsights
import SensaMonitoring
import SwiftUI

/// The home screen: greeting, overall health, one tile per component and live activity.
struct DashboardView: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Binding var selection: Destination?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                HStack(alignment: .center) {
                    GreetingHeader()
                    Spacer(minLength: Spacing.large)
                    DeviceSummary(profile: store.profile, isDemo: store.isDemo)
                }
                HealthSummaryCard(health: health)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210, maximum: 400), spacing: Spacing.large)], spacing: Spacing.large) {
                    ForEach(DashboardTiles.make(store: store, formatter: settings.formatter)) { tile in
                        Button { selection = tile.destination } label: { tile.view }
                            .buttonStyle(TileButtonStyle())
                            .accessibilityIdentifier("tile.\(tile.destination.rawValue)")
                    }
                }
                ActivityCard()
            }
            .padding(Spacing.xxLarge)
            .frame(maxWidth: 1_100, alignment: .leading)
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
            Text("\(profile.chipName) · \(MetricFormatter().bytes(profile.physicalMemory))")
                .font(Typography.caption).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.trailing)
        .accessibilityElement(children: .combine)
    }
}

private struct HealthSummaryCard: View {
    @Environment(AppSettings.self) private var settings
    let health: SystemHealth?

    var body: some View {
        Card {
            HStack(spacing: Spacing.medium) {
                Image(systemName: (health?.level ?? .normal).symbolName)
                    .font(.title)
                    .foregroundStyle((health?.level ?? .normal).tint)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(InsightText.headline(for: health)).font(Typography.title)
                    if health?.items.isEmpty ?? true {
                        Text(tr("Temperature, memory, storage and battery are within the expected range."))
                            .font(Typography.callout).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let health {
                    StatusBadge(level: health.level, text: InsightText.levelName(health.level))
                }
            }
            if let items = health?.items, !items.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(items) { item in
                        Label {
                            Text(InsightText(formatter: settings.formatter).text(for: item.insight))
                        } icon: {
                            Image(systemName: item.level == .normal ? item.component.symbolName : item.level.symbolName)
                                .foregroundStyle(item.level == .normal ? Color.accentColor : item.level.tint)
                        }
                        .font(Typography.callout)
                    }
                }
            }
        }
        .accessibilityIdentifier("dashboard.health")
    }
}

private struct ActivityCard: View {
    var body: some View {
        SeriesChartCard(
            title: tr("Activity"),
            symbol: "waveform.path.ecg",
            lines: [
                .init(metric: .cpuUsage, label: tr("CPU"), color: .blue),
                .init(metric: .gpuUsage, label: tr("GPU"), color: .purple)
            ],
            range: 0...100,
            transform: { $0 * 100 },
            format: { "\(Int($0)) %" }
        )
    }
}

private struct TileButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(Motion.quick, value: configuration.isPressed)
    }
}
