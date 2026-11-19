import iSensaCore
import iSensaDesign
import iSensaInsights
import iSensaMonitoring
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

/// Popover content: the overview in miniature, in the same visual language. Reads only cached state,
/// so it opens instantly.
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
        let cells = Self.tiles.compactMap { indicator in
            MenuBarValues.value(for: indicator, snapshot: snapshot, formatter: formatter, fanDisplay: settings.fanSpeedDisplay).map { (indicator, $0) }
        }
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header(health: health)
            if let item = health?.items.first(where: { $0.level != .normal }) {
                Label(InsightText(formatter: formatter).text(for: item.insight), systemImage: item.level.symbolName)
                    .font(Typography.caption)
                    .foregroundStyle(item.level.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // Rows of two equal columns. (A `Grid` sizes columns from their ideal widths and would
            // grow past the popover when a value such as network throughput is long.)
            VStack(spacing: 0) {
                ForEach(stride(from: 0, to: cells.count, by: 2).map { $0 }, id: \.self) { row in
                    if row > 0 { Divider() }
                    HStack(spacing: 0) {
                        CompactCell(indicator: cells[row].0, value: cells[row].1, snapshot: snapshot)
                        Rectangle().fill(Color(nsColor: .separatorColor)).frame(width: 0.5).padding(.vertical, Spacing.small)
                        if row + 1 < cells.count {
                            CompactCell(indicator: cells[row + 1].0, value: cells[row + 1].1, snapshot: snapshot)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .surface()
            if store.isDemo { ProvenanceTag(tr("Demo data"), symbol: "theatermasks") }
            footer
        }
        .padding(Spacing.large)
        .frame(width: 340)
        // A container element keeps the identifier from overwriting the children's own identifiers.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("menubar.popover")
    }

    private func header(health: SystemHealth?) -> some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Image(systemName: (health?.level ?? .normal).symbolName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle((health?.level ?? .normal).tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(store.profile.computerName ?? store.profile.displayModelName).font(Typography.headline)
                Text(InsightText.headline(for: health)).font(Typography.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack {
            Button(tr("Open iSensa"), action: actions.openMainWindow)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("o")
                .accessibilityIdentifier("menubar.open")
            Spacer()
            Button(action: actions.openSettings) { Image(systemName: "gearshape").frame(width: 22, height: 22) }
                .help(tr("Settings…")).accessibilityLabel(tr("Settings…"))
                .keyboardShortcut(",")
            Button(action: actions.quit) { Image(systemName: "power").frame(width: 22, height: 22) }
                .help(tr("Quit iSensa")).accessibilityLabel(tr("Quit iSensa"))
        }
        .buttonStyle(.borderless)
        .controlSize(.regular)
    }
}

private struct CompactCell: View {
    let indicator: MenuBarIndicator
    let value: String
    let snapshot: SystemSnapshot

    var body: some View {
        let hue = MenuBarValues.hue(for: indicator)
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(spacing: 5) {
                Image(systemName: MenuBarValues.symbol(for: indicator, snapshot: snapshot))
                    .foregroundStyle(hue.color).frame(width: 14)
                Text(MenuBarValues.title(for: indicator)).foregroundStyle(.secondary).lineLimit(1)
            }
            .font(Typography.caption)
            MetricText(value, size: .medium, minimumScale: indicator == .network ? 0.45 : 0.6)
            SeriesSparkline(metric: MenuBarValues.metric(for: indicator), range: MenuBarValues.range(for: indicator), tint: hue.color)
                .frame(height: 20)
        }
        .padding(Spacing.medium)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
