import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// A card with a live chart bound to one or more series. Each series is observed
/// individually, so only this card re-renders when its data changes.
struct SeriesChartCard: View {
    struct Line {
        let metric: MetricID
        let label: String
        let color: Color
    }

    @Environment(MetricsStore.self) private var store
    let title: String
    let symbol: String
    let lines: [Line]
    var range: ClosedRange<Double>?
    var transform: (Double) -> Double = { $0 }
    let format: (Double) -> String

    var body: some View {
        Card(title, symbol: symbol, accessory: { provenanceTag }) {
            let series = lines.map { line in
                LiveChart.Series(id: line.metric.rawValue, label: line.label, color: line.color, points: store.series(for: line.metric).points(transform))
            }
            if series.allSatisfy({ $0.points.count < 2 }) {
                WaitingView(message: tr("Collecting data…")).frame(height: 160)
            } else {
                LiveChart(series: series, range: range, format: format).frame(height: 160)
            }
        }
    }

    @ViewBuilder private var provenanceTag: some View {
        if let first = lines.first, let text = Descriptions.provenance(store.series(for: first.metric).provenance) {
            ProvenanceTag(text)
        }
    }
}

/// Sparkline bound to one series, for tiles.
struct SeriesSparkline: View {
    @Environment(MetricsStore.self) private var store
    let metric: MetricID
    var range: ClosedRange<Double>?
    var tint: Color = .accentColor

    var body: some View {
        SparklineChart(points: store.series(for: metric).points(), range: range, tint: tint)
    }
}
