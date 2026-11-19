import SensaCore
import SwiftUI

/// Dashboard tile: symbol, title, a prominent value, a friendly caption and an optional chart.
public struct MetricTile<Chart: View>: View {
    private let title: String
    private let symbol: String
    private let value: String
    private let caption: String
    private let level: HealthLevel?
    private let chart: Chart

    public init(
        title: String,
        symbol: String,
        value: String,
        caption: String,
        level: HealthLevel? = nil,
        @ViewBuilder chart: () -> Chart = { EmptyView() }
    ) {
        self.title = title
        self.symbol = symbol
        self.value = value
        self.caption = caption
        self.level = level
        self.chart = chart()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 18)
                Text(title).font(Typography.callout.weight(.medium)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if let level, level != .normal {
                    Image(systemName: level.symbolName).foregroundStyle(level.tint)
                }
            }
            Text(value)
                .font(Typography.metric)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
            chart.frame(height: 36)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface()
        .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value). \(caption)")
    }
}
