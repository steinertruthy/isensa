import SensaCore
import SwiftUI

/// Capsule combining symbol, text and tint for a health level.
public struct StatusBadge: View {
    private let level: HealthLevel
    private let text: String

    public init(level: HealthLevel, text: String) {
        self.level = level
        self.text = text
    }

    public var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: level.symbolName)
        }
        .font(Typography.caption.weight(.medium))
        .foregroundStyle(level.tint)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(level.tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

/// Small neutral capsule that states where a number comes from (Estimated, Derived, Demo…).
public struct ProvenanceTag: View {
    private let text: String
    private let symbol: String

    public init(_ text: String, symbol: String = "info.circle") {
        self.text = text
        self.symbol = symbol
    }

    public var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.6), in: Capsule())
            .accessibilityLabel(text)
    }
}
