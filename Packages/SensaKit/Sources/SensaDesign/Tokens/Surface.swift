import SwiftUI

/// The single place where surfaces adapt to the OS: content sits on quiet, opaque-ish
/// fills (legible, low-energy); floating chrome uses Liquid Glass on macOS 26 and
/// native materials on macOS 14–15.
public enum SurfaceStyle {
    case content
    case floating
}

private struct SurfaceModifier: ViewModifier {
    let style: SurfaceStyle
    let radius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        switch style {
        case .content:
            content
                // Light: white panel lifted by a hairline and a whisper of shadow.
                // Dark: a slightly raised fill; shadows read as dirt on dark backgrounds.
                .background(shape.fill(colorScheme == .dark ? Color.white.opacity(0.055) : Color(nsColor: .controlBackgroundColor)))
                .overlay(shape.strokeBorder(Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.6 : 0.45), lineWidth: 0.5))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.035), radius: 3, y: 1)
        case .floating:
            if #available(macOS 26, *) {
                content.glassEffect(.regular, in: shape)
            } else {
                content.background(.regularMaterial, in: shape)
            }
        }
    }
}

public extension View {
    func surface(_ style: SurfaceStyle = .content, radius: CGFloat = Radius.large) -> some View {
        modifier(SurfaceModifier(style: style, radius: radius))
    }
}
