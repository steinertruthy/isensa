import SensaCore
import SwiftUI

/// One metric inside a `CellGroup`: hued symbol and title, typeset value, plain-language caption
/// and an optional chart. Acts as a button with a quiet hover and press state.
public struct MetricCell<Chart: View>: View {
    private let title: String
    private let symbol: String
    private let hue: Hue
    private let value: String
    private let caption: String
    private let level: HealthLevel?
    private let action: (() -> Void)?
    private let chart: Chart
    @State private var isHovered = false

    public init(
        title: String,
        symbol: String,
        hue: Hue,
        value: String,
        caption: String,
        level: HealthLevel? = nil,
        action: (() -> Void)? = nil,
        // No default on purpose: with two defaulted closures, a trailing chart closure would bind to `action`.
        @ViewBuilder chart: () -> Chart
    ) {
        self.title = title
        self.symbol = symbol
        self.hue = hue
        self.value = value
        self.caption = caption
        self.level = level
        self.action = action
        self.chart = chart()
    }

    public var body: some View {
        Button { action?() } label: { content }
            .buttonStyle(CellButtonStyle(isHovered: isHovered))
            .disabled(action == nil)
            .onHover { isHovered = $0 && action != nil }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(value). \(caption)")
            .accessibilityAddTraits(action == nil ? [] : .isButton)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(hue.color)
                    .frame(width: 16)
                Text(title).font(Typography.callout.weight(.medium)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if let level, level != .normal {
                    Image(systemName: level.symbolName).foregroundStyle(level.tint)
                        .accessibilityLabel(level == .critical ? "critical" : "attention")
                }
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .opacity(isHovered ? 1 : 0)
                        .accessibilityHidden(true)
                }
            }
            MetricText(value, size: .large)
                .padding(.top, Spacing.xxSmall)
            Text(caption)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
            chart
                .frame(height: 30)
                .padding(.top, Spacing.xSmall)
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct CellButtonStyle: ButtonStyle {
    let isHovered: Bool
    @Environment(\.sensaMotion) private var preference
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.08 : isHovered ? 0.04 : 0)
            )
            .animation(Motion.resolve(Motion.quick, preference: preference, reduceMotion: reduceMotion), value: isHovered)
            .animation(Motion.resolve(Motion.quick, preference: preference, reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
