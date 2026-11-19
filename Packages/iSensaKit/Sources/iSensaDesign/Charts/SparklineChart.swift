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
    private let reference: Double?

    /// - Parameter reference: a value to mark with a dashed line, such as a fan's target speed.
    public init(points: [Point], range: ClosedRange<Double>? = nil, tint: Color = .accentColor, reference: Double? = nil) {
        self.points = points
        self.range = range
        self.tint = tint
        self.reference = reference
    }

    public var body: some View {
        // The fill starts at the bottom of the visible domain, not at zero: with a domain that
        // excludes zero (e.g. 40–60 °C) a zero-based area would be drawn below the chart.
        let baseline = range?.lowerBound ?? 0
        Chart(points) { point in
            AreaMark(
                x: .value("Time", point.date),
                yStart: .value("Baseline", baseline),
                yEnd: .value("Value", point.value)
            )
                .foregroundStyle(LinearGradient(colors: [tint.opacity(0.32), tint.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Time", point.date), y: .value("Value", point.value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.monotone)
        }
        .modifier(ReferenceLine(reference: reference, tint: tint))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .modifier(OptionalYScale(range: range))
        // Swift Charts does not clip marks to the plot area; never let a chart paint outside its card.
        .chartPlotStyle { $0.clipped() }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Draws the reference as a dashed rule in the chart's own coordinate space.
private struct ReferenceLine: ViewModifier {
    let reference: Double?
    let tint: Color

    func body(content: Content) -> some View {
        if let reference {
            content.chartBackground { proxy in
                GeometryReader { geometry in
                    if let plot = proxy.plotFrame, let y = proxy.position(forY: reference) {
                        let frame = geometry[plot]
                        Path { path in
                            path.move(to: CGPoint(x: frame.minX, y: frame.minY + y))
                            path.addLine(to: CGPoint(x: frame.maxX, y: frame.minY + y))
                        }
                        .stroke(tint.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                }
            }
        } else {
            content
        }
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
