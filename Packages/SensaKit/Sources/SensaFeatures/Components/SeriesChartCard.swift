import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// A titled live chart bound to one or more series. Each series is observed individually,
/// so only this chart re-renders when its data changes.
struct SeriesChartCard: View {
    struct Line {
        let metric: MetricID
        let label: String
        let color: Color
    }

    @Environment(MetricsStore.self) private var store
    let title: String
    let lines: [Line]
    var range: ClosedRange<Double>?
    var transform: (Double) -> Double = { $0 }
    let format: (Double) -> String

    var body: some View {
        Card(title, accessory: { provenanceTag }) {
            let series = lines.map { line in
                LiveChart.Series(id: line.metric.rawValue, label: line.label, color: line.color, points: store.series(for: line.metric).points(transform))
            }
            if series.allSatisfy({ $0.points.count < 2 }) {
                WaitingView(message: tr("Collecting data…")).frame(height: 150)
            } else {
                LiveChart(series: series, range: range, format: format).frame(height: 150)
            }
        }
    }

    @ViewBuilder private var provenanceTag: some View {
        if let first = lines.first, let text = Descriptions.provenance(store.series(for: first.metric).provenance) {
            ProvenanceTag(text)
        }
    }
}

/// Sparkline bound to one series, for cells.
struct SeriesSparkline: View {
    @Environment(MetricsStore.self) private var store
    let metric: MetricID
    var range: ClosedRange<Double>?
    var tint: Color = .accentColor
    /// Marked with a dashed line and kept inside the visible range (e.g. a fan's target speed).
    var reference: Double?

    var body: some View {
        let points = store.series(for: metric).points()
        let values = points.map(\.value) + (reference.map { [$0] } ?? [])
        let resolved = range == 0...1 ? Self.utilizationRange(values) : range ?? Self.paddedRange(values)
        SparklineChart(points: points, range: resolved, tint: tint, reference: reference)
    }

    /// Utilization keeps zero as the baseline but scales to the data (at least 25 %), so light
    /// activity is visible instead of a flat line hugging the bottom.
    nonisolated static func utilizationRange(_ values: [Double]) -> ClosedRange<Double> {
        0...min(max((values.max() ?? 0) * 1.25, 0.25), 1)
    }

    /// Without a natural scale, frame the data itself (with a little headroom) instead of
    /// starting at zero, which would flatten temperature and memory lines.
    nonisolated static func paddedRange(_ values: [Double]) -> ClosedRange<Double>? {
        guard let low = values.min(), let high = values.max() else { return nil }
        let padding = max((high - low) * 0.25, abs(high) * 0.02, 0.5)
        return (low - padding)...(high + padding)
    }
}
