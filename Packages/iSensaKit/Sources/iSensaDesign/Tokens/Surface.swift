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
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let isDark = colorScheme == .dark
        let isIncreased = contrast == .increased
        switch style {
        case .content:
            content
                // Light: white panel lifted by a hairline and a whisper of shadow.
                // Dark: a slightly raised fill; shadows read as dirt on dark backgrounds.
                // (Measured: keeping the shadow on the whole surface is cheaper than on the shape alone.)
                .background(shape.fill(isDark ? Color.white.opacity(isIncreased ? 0.1 : 0.055) : Color(nsColor: .controlBackgroundColor)))
                // Increase Contrast: a clearly visible edge.
                .overlay(shape.strokeBorder(
                    Color(nsColor: .separatorColor).opacity(isIncreased ? 1 : (isDark ? 0.6 : 0.45)),
                    lineWidth: isIncreased ? 1 : 0.5
                ))
                .shadow(color: .black.opacity(isDark ? 0 : 0.035), radius: 3, y: 1)
        case .floating:
            if reduceTransparency {
                content.background(Color(nsColor: .windowBackgroundColor), in: shape)
                    .overlay(shape.strokeBorder(Color(nsColor: .separatorColor), lineWidth: isIncreased ? 1 : 0.5))
            } else if #available(macOS 26, *) {
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
