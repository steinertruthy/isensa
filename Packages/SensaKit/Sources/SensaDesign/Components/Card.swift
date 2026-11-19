import SwiftUI

/// A titled group: the title sits above one quiet surface, as in System Settings.
/// Use one `Card` per *group* of related content — never one per number.
public struct Card<Content: View, Accessory: View>: View {
    private let title: String?
    private let accessory: Accessory
    private let content: Content

    public init(
        _ title: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.accessory = accessory()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if title != nil || !(accessory is EmptyView) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    if let title {
                        Text(title).font(Typography.headline)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Spacer(minLength: Spacing.small)
                    accessory
                }
                .padding(.horizontal, Spacing.xSmall)
            }
            VStack(alignment: .leading, spacing: Spacing.medium) { content }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surface()
        }
    }
}

/// Several cells sharing one surface, separated by hairlines (see `CellDivider`).
public struct CellGroup<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) { content }
            .fixedSize(horizontal: false, vertical: true)
            // Clip so hover/press highlights of edge cells follow the rounded corners.
            .clipShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .surface()
    }
}

/// Vertical hairline between cells of a `CellGroup`.
public struct CellDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1 / (NSScreen.main?.backingScaleFactor ?? 2))
            .padding(.vertical, Spacing.medium)
            .accessibilityHidden(true)
    }
}
