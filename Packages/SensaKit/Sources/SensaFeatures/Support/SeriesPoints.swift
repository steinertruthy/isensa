import SensaDesign
import SensaMonitoring

extension MetricSeries {
    /// Chart points, optionally transformed (e.g. fraction → percent, °C → °F).
    func points(_ transform: (Double) -> Double = { $0 }) -> [SparklineChart.Point] {
        samples.map { SparklineChart.Point(date: $0.timestamp, value: transform($0.value)) }
    }
}
