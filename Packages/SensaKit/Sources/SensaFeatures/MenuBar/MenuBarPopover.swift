import SensaCore
import SensaDesign
import SensaInsights
import SensaMonitoring
import SwiftUI

/// Actions the popover needs from the app layer.
public struct MenuBarActions {
    public var openMainWindow: () -> Void
    public var openSettings: () -> Void
    public var quit: () -> Void

    public init(openMainWindow: @escaping () -> Void, openSettings: @escaping () -> Void, quit: @escaping () -> Void) {
        self.openMainWindow = openMainWindow
        self.openSettings = openSettings
        self.quit = quit
    }
}

/// Popover content. Reads only cached state, so it opens instantly.
public struct MenuBarPopover: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    private let actions: MenuBarActions

    public init(actions: MenuBarActions) {
        self.actions = actions
    }

    public var body: some View {
        let formatter = settings.formatter
        let snapshot = store.snapshot
        let health = HealthEvaluator().evaluate(snapshot)
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(store.profile.computerName ?? store.profile.displayModelName).font(Typography.headline)
                    Text(store.profile.chipName).font(Typography.caption).foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(level: health.level, text: InsightText.levelName(health.level))
            }
            Text(InsightText.headline(for: snapshot == SystemSnapshot() ? nil : health))
                .font(Typography.callout).foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.small), GridItem(.flexible())], spacing: Spacing.small) {
                ForEach(MenuBarIndicator.allCases) { indicator in
                    if let value = MenuBarValues.value(for: indicator, snapshot: snapshot, formatter: formatter) {
                        CompactTile(indicator: indicator, value: value)
                    }
                }
            }

            if store.isDemo { ProvenanceTag(tr("Demo data"), symbol: "theatermasks") }

            Divider()
            HStack {
                Button(tr("Open Sensa"), action: actions.openMainWindow).keyboardShortcut("o")
                Spacer()
                Button(action: actions.openSettings) { Image(systemName: "gearshape") }
                    .help(tr("Settings…")).accessibilityLabel(tr("Settings…"))
                Button(action: actions.quit) { Image(systemName: "power") }
                    .help(tr("Quit Sensa")).accessibilityLabel(tr("Quit Sensa"))
            }
            .buttonStyle(.borderless)
        }
        .padding(Spacing.large)
        .frame(width: 340)
    }
}

private struct CompactTile: View {
    let indicator: MenuBarIndicator
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(MenuBarValues.title(for: indicator), systemImage: MenuBarValues.symbol(for: indicator))
                .font(Typography.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(value).font(Typography.metricSmall).contentTransition(.numericText()).lineLimit(1)
            if let metric = MenuBarValues.metric(for: indicator) {
                SeriesSparkline(metric: metric, tint: .accentColor).frame(height: 22)
            }
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
