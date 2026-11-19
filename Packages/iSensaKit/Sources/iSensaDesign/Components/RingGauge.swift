import SwiftUI

/// Circular progress with a soft track. Fills from zero when it appears, then follows value changes,
/// both per the motion preference.
public struct RingGauge<Label: View>: View {
    private let value: Double
    private let tint: Color
    private let lineWidth: CGFloat
    private let label: Label
    @State private var revealed = false

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
                .trim(from: 0, to: revealed ? min(max(value, 0), 1) : 0)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
        .iSensaAnimation(Motion.update, value: value)
        .revealOnAppear($revealed)
    }
}
