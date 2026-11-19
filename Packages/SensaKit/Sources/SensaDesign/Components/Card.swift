import SwiftUI

/// Content container with consistent padding and surface. Optional title row.
public struct Card<Content: View, Accessory: View>: View {
    private let title: String?
    private let symbol: String?
    private let accessory: Accessory
    private let content: Content

    public init(
        _ title: String? = nil,
        symbol: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.accessory = accessory()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if let title {
                HStack(spacing: Spacing.small) {
                    if let symbol {
                        Image(systemName: symbol).foregroundStyle(.secondary)
                    }
                    Text(title).font(Typography.headline)
                    Spacer(minLength: Spacing.small)
                    accessory
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface()
    }
}
