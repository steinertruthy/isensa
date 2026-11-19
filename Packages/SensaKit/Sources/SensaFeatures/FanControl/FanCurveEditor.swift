import Charts
import SensaControl
import SensaDesign
import SwiftUI

/// The selected curve, with the macOS-controlled zone shaded and the control temperature marked.
/// With `onMove`, its points can be dragged; the curve's own rules decide where they may go.
struct FanCurveChart: View {
    let curve: FanCurve
    let temperature: Double?
    let formatter: MetricFormatter
    /// Point index, requested temperature and requested speed fraction.
    var onMove: ((Int, Double, Double) -> Void)?

    @State private var dragged: Int?
    /// How close (in points) a drag must start to grab a curve point.
    private static let grabRadius: CGFloat = 24

    var body: some View {
        let samples = stride(from: 30.0, through: 100, by: 1).map { ($0, curve.fraction(at: $0)) }
        Chart {
            if let quiet = curve.systemControlBelow {
                RectangleMark(xStart: .value("From", 30), xEnd: .value("To", quiet), yStart: .value("Bottom", 0), yEnd: .value("Top", 1))
                    .foregroundStyle(Color.secondary.opacity(0.08))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("macOS").font(Typography.caption).foregroundStyle(.secondary)
                    }
            }
            ForEach(samples, id: \.0) { sample in
                LineMark(x: .value("Temperature", sample.0), y: .value("Speed", sample.1))
                    .foregroundStyle(Hue.fans.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            if onMove != nil {
                ForEach(Array(curve.points.enumerated()), id: \.offset) { index, point in
                    PointMark(x: .value("Temperature", point.celsius), y: .value("Speed", point.fraction))
                        .symbolSize(dragged == index ? 150 : 90)
                        .foregroundStyle(Hue.fans.color)
                }
            }
            if let temperature {
                RuleMark(x: .value("Now", min(max(temperature, 30), 100)))
                    .foregroundStyle(Hue.thermal.color)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text(formatter.temperature(temperature)).font(Typography.caption).foregroundStyle(Hue.thermal.color)
                    }
            }
        }
        .chartXScale(domain: 30...100)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1]) { value in
                AxisGridLine()
                AxisValueLabel { Text(value.as(Double.self).map { $0 == 0 ? tr("Min") : $0 == 1 ? tr("Max") : "50%" } ?? "") }
            }
        }
        .chartXAxis {
            AxisMarks(values: [40, 60, 80, 100]) { value in
                AxisGridLine()
                AxisValueLabel { Text(value.as(Double.self).map { formatter.temperature($0) } ?? "") }
            }
        }
        .chartOverlay { proxy in
            if let onMove {
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(drag(proxy: proxy, geometry: geometry, onMove: onMove))
                }
            }
        }
        .animation(Motion.update, value: dragged)
        .accessibilityLabel(tr("Fan curve"))
        .accessibilityIdentifier("fans.curve")
    }

    private func drag(proxy: ChartProxy, geometry: GeometryProxy, onMove: @escaping (Int, Double, Double) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let anchor = proxy.plotFrame else { return }
                let frame = geometry[anchor]
                if dragged == nil { dragged = nearestPoint(to: value.startLocation, in: frame, proxy: proxy) }
                guard let index = dragged,
                      let celsius: Double = proxy.value(atX: value.location.x - frame.minX),
                      let fraction: Double = proxy.value(atY: value.location.y - frame.minY) else { return }
                onMove(index, celsius, fraction)
            }
            .onEnded { _ in dragged = nil }
    }

    private func nearestPoint(to location: CGPoint, in frame: CGRect, proxy: ChartProxy) -> Int? {
        let distances = curve.points.enumerated().compactMap { index, point -> (index: Int, distance: CGFloat)? in
            guard let x = proxy.position(forX: point.celsius), let y = proxy.position(forY: point.fraction) else { return nil }
            return (index, hypot(frame.minX + x - location.x, frame.minY + y - location.y))
        }
        return distances.filter { $0.distance <= Self.grabRadius }.min { $0.distance < $1.distance }?.index
    }
}

/// Everything the chart's drag does, reachable from the keyboard and VoiceOver, plus the quiet zone.
struct CustomCurveControls: View {
    let curve: FanCurve
    let formatter: MetricFormatter
    let onChange: (FanCurve) -> Void

    @State private var showsValues = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(tr("Drag the points to shape the curve. Speed never drops as the temperature rises, and the last point is always full speed."))
                .font(Typography.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Toggle(
                tr("Leave the fans to macOS below the first point"),
                isOn: Binding(get: { curve.systemControlBelow != nil }, set: { onChange(curve.leavingFansToMacOSBelowFirstPoint($0)) })
            )
            .accessibilityIdentifier("fans.custom.macos")
            DisclosureGroup(tr("Adjust values"), isExpanded: $showsValues) {
                Grid(alignment: .leading, horizontalSpacing: Spacing.large, verticalSpacing: Spacing.small) {
                    ForEach(Array(curve.points.enumerated()), id: \.offset) { index, point in
                        row(index: index, point: point)
                    }
                }
                .padding(.top, Spacing.small)
            }
            .accessibilityIdentifier("fans.custom.values")
        }
    }

    private func row(index: Int, point: FanCurve.Point) -> some View {
        let number = "\(index + 1)"
        let isLast = index == curve.points.count - 1
        let temperature = formatter.temperature(point.celsius)
        let speed = formatter.percent(point.fraction)
        return GridRow {
            Text(number).foregroundStyle(.secondary).monospacedDigit()
            Stepper {
                Text(temperature).monospacedDigit().frame(minWidth: 52, alignment: .trailing)
            } onIncrement: {
                move(index, celsius: point.celsius + FanCurve.temperatureStep, fraction: point.fraction)
            } onDecrement: {
                move(index, celsius: point.celsius - FanCurve.temperatureStep, fraction: point.fraction)
            }
            .accessibilityLabel(tr("Point %@ temperature", number))
            .accessibilityValue(temperature)
            Stepper {
                Text(speed).monospacedDigit().frame(minWidth: 44, alignment: .trailing)
            } onIncrement: {
                move(index, celsius: point.celsius, fraction: point.fraction + FanCurve.fractionStep)
            } onDecrement: {
                move(index, celsius: point.celsius, fraction: point.fraction - FanCurve.fractionStep)
            }
            .disabled(isLast)
            .accessibilityLabel(tr("Point %@ speed", number))
            .accessibilityValue(speed)
        }
    }

    private func move(_ index: Int, celsius: Double, fraction: Double) {
        onChange(curve.moving(pointAt: index, celsius: celsius, fraction: fraction))
    }
}
