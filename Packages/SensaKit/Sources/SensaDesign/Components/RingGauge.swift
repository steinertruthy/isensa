import SwiftUI

/// Circular progress with a soft track. Animates value changes unless Reduce Motion is on.
public struct RingGauge<Label: View>: View {
    private let value: Double
    private let tint: Color
    private let lineWidth: CGFloat
    private let label: Label
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(value: Double, tint: Color = .accentColor, lineWidth: CGFloat = 10, @ViewBuilder label: () -> Label) {
        self.value = value
        self.tint = tint
        self.lineWidth = lineWidth
        self.label = label()
    }

    public var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: value)
    }
}
