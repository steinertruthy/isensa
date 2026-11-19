import SwiftUI

/// A linear meter (clock speed, volume usage) that fills from zero when it appears and then follows
/// value changes, both per the motion preference.
public struct MeterBar: View {
    private let value: Double
    private let tint: Color
    @State private var revealed = false

    public init(value: Double, tint: Color) {
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        ProgressView(value: revealed ? min(max(value, 0), 1) : 0)
            .tint(tint)
            .iSensaAnimation(Motion.update, value: value)
            .revealOnAppear($revealed)
    }
}
