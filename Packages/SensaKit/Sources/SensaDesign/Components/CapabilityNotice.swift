import SwiftUI

/// Explains, calmly and specifically, why something is not available on this Mac.
public struct CapabilityNotice: View {
    private let symbol: String
    private let title: String
    private let message: String

    public init(symbol: String, title: String, message: String) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: symbol)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title).font(Typography.headline)
                Text(message).font(Typography.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
