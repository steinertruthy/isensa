import SensaCore
import SensaMonitoring

/// Everything the status item draws, as a plain value. The app renders it with AppKit
/// (no SwiftUI renderer in the menu bar) and only when the value actually changes.
public struct MenuBarLabelModel: Equatable, Sendable {
    public struct Item: Equatable, Sendable {
        /// SF Symbol name, or `nil` when icons are hidden.
        public let symbol: String?
        public let text: String
        /// Normalised `0...1` points, oldest first, when the indicator shows a graph.
        public let sparkline: [Double]?
    }

    public let items: [Item]
    public let layout: MenuBarLayout

    /// Shown when no indicator is enabled or none has data yet.
    public static let fallbackSymbol = "gauge.with.dots.needle.67percent"

    @MainActor
    public static func make(store: MetricsStore, settings: AppSettings, sparklineLength: Int = 24) -> MenuBarLabelModel {
        let snapshot = store.snapshot
        let formatter = settings.formatter
        let items: [Item] = settings.enabledMenuBarItems.compactMap { configuration in
            let indicator = configuration.indicator
            guard let text = MenuBarValues.value(
                for: indicator, snapshot: snapshot, formatter: formatter, decimals: settings.menuBarDecimals
            ) else { return nil }
            let sparkline = configuration.showsSparkline
                ? normalized(store.series(for: MenuBarValues.metric(for: indicator)).samples.suffix(sparklineLength).map(\.value),
                             range: MenuBarValues.range(for: indicator))
                : nil
            return Item(
                symbol: settings.menuBarShowsIcons ? MenuBarValues.symbol(for: indicator, snapshot: snapshot) : nil,
                text: text,
                sparkline: sparkline
            )
        }
        return MenuBarLabelModel(items: items, layout: settings.menuBarLayout)
    }

    /// Scales values into `0...1`, using a fixed range when the metric has one.
    static func normalized(_ values: [Double], range: ClosedRange<Double>?) -> [Double] {
        guard let low = range?.lowerBound ?? values.min(), let high = range?.upperBound ?? values.max() else { return [] }
        let span = high - low
        guard span > 0 else { return values.map { _ in 0.5 } }
        return values.map { min(max(($0 - low) / span, 0), 1) }
    }
}
