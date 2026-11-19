import iSensaDesign
import SwiftUI

/// A sidebar row pinned below the list — for places that open elsewhere (such as Settings) rather
/// than being selected. Matches the list rows' icon, type and insets; highlights on hover and press.
struct SidebarFooterButton: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.iSensaMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Label { Text(title) } icon: { SidebarIcon(symbol, hue: .neutral) }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(FooterStyle(isHovered: isHovered))
        .onHover { hovering in
            withAnimation(Motion.resolve(Motion.quick, preference: motion, reduceMotion: reduceMotion)) { isHovered = hovering }
        }
        .padding(.horizontal, Spacing.small + 2)
        .padding(.bottom, Spacing.small + 2)
    }

    private struct FooterStyle: ButtonStyle {
        let isHovered: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                        .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : isHovered ? 0.06 : 0))
                )
        }
    }
}
