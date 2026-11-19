import Charts
import SwiftUI

/// Detailed live chart with axes, used on component screens. Supports several series.
public struct LiveChart: View {
    public struct Series: Identifiable {
        public let id: String
        public let label: String
        public let color: Color
        public let points: [SparklineChart.Point]

        public init(id: String, label: String, color: Color, points: [SparklineChart.Point]) {
            self.id = id
            self.label = label
            self.color = color
            self.points = points
        }
    }

    private let series: [Series]
    private let range: ClosedRange<Double>?
    private let format: (Double) -> String

    public init(series: [Series], range: ClosedRange<Double>? = nil, format: @escaping (Double) -> String) {
        self.series = series
        self.range = range
        self.format = format
    }

    public var body: some View {
        Chart {
            ForEach(series) { item in
                ForEach(item.points) { point in
                    LineMark(x: .value("Time", point.date), y: .value(item.label, point.value), series: .value("Series", item.label))
                        .foregroundStyle(item.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                }
                if series.count == 1 {
                    ForEach(item.points) { point in
                        AreaMark(
                            x: .value("Time", point.date),
                            yStart: .value("Baseline", range?.lowerBound ?? 0),
                            yEnd: .value(item.label, point.value)
                        )
                            .foregroundStyle(LinearGradient(colors: [item.color.opacity(0.25), item.color.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.monotone)
                    }
                }
            }
        }
        .chartForegroundStyleScale(domain: series.map(\.label), range: series.map(\.color))
        .chartLegend(series.count > 1 ? .visible : .hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .second, count: 30)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                AxisValueLabel {
                    if let number = value.as(Double.self) { Text(format(number)).monospacedDigit() }
                }
            }
        }
        .modifier(OptionalYScale(range: range))
        .chartPlotStyle { $0.clipped() }
        .accessibilityElement()
        .accessibilityLabel(series.map(\.label).joined(separator: ", "))
        .accessibilityValue(series.compactMap { item in item.points.last.map { "\(item.label): \(format($0.value))" } }.joined(separator: ", "))
    }
}
