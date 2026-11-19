import SwiftUI

/// Drawn battery with animated fill and a gentle charging pulse (static under Reduce Motion).
public struct BatteryGlyph: View {
    private let charge: Double
    private let isCharging: Bool
    private let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    public init(charge: Double, isCharging: Bool, tint: Color) {
        self.charge = min(max(charge, 0), 1)
        self.isCharging = isCharging
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geometry in
            let capWidth = geometry.size.width * 0.05
            let bodyWidth = geometry.size.width - capWidth - 3
            let radius = geometry.size.height * 0.24
            HStack(spacing: 3) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.45), lineWidth: 2)
                    RoundedRectangle(cornerRadius: radius - 4, style: .continuous)
                        .fill(tint.gradient)
                        .frame(width: max((bodyWidth - 10) * charge, 4))
                        .padding(5)
                        .opacity(isCharging && pulse ? 0.78 : 1)
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: geometry.size.height * 0.42, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 2)
                            .frame(maxWidth: .infinity)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: bodyWidth)
                RoundedRectangle(cornerRadius: capWidth / 2, style: .continuous)
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: capWidth, height: geometry.size.height * 0.36)
            }
        }
        .aspectRatio(2.1, contentMode: .fit)
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: charge)
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: isCharging)
        .onChange(of: isCharging, initial: true) { _, charging in
            guard charging, !reduceMotion else {
                pulse = false
                return
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityHidden(true)
    }
}
