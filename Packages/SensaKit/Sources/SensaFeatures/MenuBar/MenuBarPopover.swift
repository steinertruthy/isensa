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

    /// Curated overview, independent of which indicators sit in the menu bar.
    static let tiles: [MenuBarIndicator] = [.cpuUsage, .gpuUsage, .cpuTemperature, .memoryUsed, .battery, .power, .fans, .network]

    public init(actions: MenuBarActions) {
        self.actions = actions
    }

    public var body: some View {
        let formatter = settings.formatter
        let snapshot = store.snapshot
        let health = snapshot == SystemSnapshot() ? nil : HealthEvaluator().evaluate(snapshot)
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header(health: health)
            if let item = health?.items.first(where: { $0.level != .normal }) {
                Label(InsightText(formatter: formatter).text(for: item.insight), systemImage: item.level.symbolName)
                    .font(Typography.caption)
                    .foregroundStyle(item.level.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.small), GridItem(.flexible())], spacing: Spacing.small) {
                ForEach(Self.tiles) { indicator in
                    if let value = MenuBarValues.value(for: indicator, snapshot: snapshot, formatter: formatter) {
                        CompactTile(indicator: indicator, value: value, symbol: MenuBarValues.symbol(for: indicator, snapshot: snapshot))
                    }
                }
            }
            if store.isDemo { ProvenanceTag(tr("Demo data"), symbol: "theatermasks") }
            Divider()
            footer
        }
        .padding(Spacing.large)
        .frame(width: 340)
        // A container element keeps the identifier from overwriting the children's own identifiers.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("menubar.popover")
    }

    private func header(health: SystemHealth?) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(store.profile.computerName ?? store.profile.displayModelName).font(Typography.headline)
                Text(InsightText.headline(for: health)).font(Typography.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.small)
            if let health {
                StatusBadge(level: health.level, text: InsightText.levelName(health.level))
            }
        }
    }

    private var footer: some View {
        HStack {
            Button(tr("Open Sensa"), action: actions.openMainWindow)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .keyboardShortcut("o")
                .accessibilityIdentifier("menubar.open")
            Spacer()
            Button(action: actions.openSettings) { Image(systemName: "gearshape") }
                .help(tr("Settings…")).accessibilityLabel(tr("Settings…"))
                .keyboardShortcut(",")
            Button(action: actions.quit) { Image(systemName: "power") }
                .help(tr("Quit Sensa")).accessibilityLabel(tr("Quit Sensa"))
        }
        .buttonStyle(.borderless)
    }
}

private struct CompactTile: View {
    let indicator: MenuBarIndicator
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(MenuBarValues.title(for: indicator), systemImage: symbol)
                .font(Typography.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(value).font(Typography.metricSmall).contentTransition(.numericText()).lineLimit(1).minimumScaleFactor(0.7)
            SeriesSparkline(metric: MenuBarValues.metric(for: indicator), range: MenuBarValues.range(for: indicator), tint: .accentColor)
                .frame(height: 22)
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
