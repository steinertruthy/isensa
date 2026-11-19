import Charts
import SwiftUI

/// Minimal live chart for tiles and the menu bar popover: no axes, soft gradient fill.
public struct SparklineChart: View {
    public struct Point: Identifiable, Hashable {
        public let date: Date
        public let value: Double
        public var id: Date { date }

        public init(date: Date, value: Double) {
            self.date = date
            self.value = value
        }
    }

    private let points: [Point]
    private let range: ClosedRange<Double>?
    private let tint: Color

    public init(points: [Point], range: ClosedRange<Double>? = nil, tint: Color = .accentColor) {
        self.points = points
        self.range = range
        self.tint = tint
    }

    public var body: some View {
        Chart(points) { point in
            AreaMark(x: .value("Time", point.date), y: .value("Value", point.value))
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.32), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Time", point.date), y: .value("Value", point.value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .modifier(OptionalYScale(range: range))
        .accessibilityHidden(true)
    }
}

struct OptionalYScale: ViewModifier {
    let range: ClosedRange<Double>?

    func body(content: Content) -> some View {
        if let range {
            content.chartYScale(domain: range)
        } else {
            content
        }
    }
}
