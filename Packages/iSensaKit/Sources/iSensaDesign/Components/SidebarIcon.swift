import SwiftUI

/// System Settings–style icon: a white glyph on a rounded square in the component's hue.
public struct SidebarIcon: View {
    private let symbol: String
    private let hue: Hue
    private let size: CGFloat
    private let isSelected: Bool
    private let bouncesOnAppear: Bool
    @State private var bounces = 0
    @Environment(\.iSensaMotion) private var preference
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isSelected: the glyph gives a small bounce when the row becomes selected.
    ///   - bouncesOnAppear: the glyph bounces once when it appears (screen headers).
    public init(_ symbol: String, hue: Hue, size: CGFloat = 20, isSelected: Bool = false, bouncesOnAppear: Bool = false) {
        self.symbol = symbol
        self.hue = hue
        self.size = size
        self.isSelected = isSelected
        self.bouncesOnAppear = bouncesOnAppear
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.55, weight: .semibold))
            .symbolEffect(.bounce.down, options: .nonRepeating.speed(1.4), value: bounces)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                    .fill(hue.color.gradient)
                    .shadow(color: .black.opacity(0.12), radius: 0.5, y: 0.5)
            )
            .accessibilityHidden(true)
            .onChange(of: isSelected) { _, selected in if selected { bounce() } }
            .onAppear { if bouncesOnAppear { bounce() } }
    }

    /// Symbol effects are movement: they run only with full motion.
    private func bounce() {
        guard Motion.effective(preference, reduceMotion: reduceMotion) == .full else { return }
        bounces += 1
    }
}
