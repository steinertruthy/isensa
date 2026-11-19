import SwiftUI

/// Horizontal stacked bar (memory breakdown, storage usage). Each segment has a legend entry.
public struct SegmentedMeter: View {
    public struct Segment: Identifiable, Hashable {
        public let id: String
        public let label: String
        public let value: Double
        public let color: Color
        public let detail: String

        public init(id: String, label: String, value: Double, color: Color, detail: String) {
            self.id = id
            self.label = label
            self.value = value
            self.color = color
            self.detail = detail
        }
    }

    private let segments: [Segment]
    private let total: Double
    private let showsLegend: Bool
    @State private var revealed = false

    public init(segments: [Segment], total: Double, showsLegend: Bool = true) {
        self.segments = segments
        self.total = max(total, 1)
        self.showsLegend = showsLegend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(segment.color.gradient)
                            .frame(width: revealed ? max(geometry.size.width * segment.value / total - 2, 0) : 0)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 12)
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .iSensaAnimation(Motion.update, value: segments)
            .revealOnAppear($revealed)
            .accessibilityHidden(true)

            if showsLegend {
                FlowLayout {
                    ForEach(segments) { segment in
                        HStack(spacing: Spacing.small) {
                            Circle().fill(segment.color).frame(width: 8, height: 8)
                            Text(segment.label).foregroundStyle(.secondary)
                            Text(segment.detail).monospacedDigit()
                        }
                        .font(Typography.callout)
                        .fixedSize()
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
