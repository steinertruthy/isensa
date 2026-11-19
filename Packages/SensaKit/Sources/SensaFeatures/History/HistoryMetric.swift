import Foundation
import SensaCore
import SensaDesign

/// How each recorded metric is titled, colored and formatted on the History screen.
struct HistoryMetric: Identifiable {
    let metric: MetricID
    let title: String
    let hue: Hue
    /// Converts a stored value to the displayed one.
    let format: (Double) -> String

    var id: MetricID { metric }

    static func all(formatter: MetricFormatter, hasBattery: Bool) -> [HistoryMetric] {
        var metrics = [
            HistoryMetric(metric: .cpuUsage, title: tr("CPU"), hue: .cpu) { formatter.percent($0) },
            HistoryMetric(metric: .gpuUsage, title: tr("GPU"), hue: .gpu) { formatter.percent($0) },
            HistoryMetric(metric: .memoryPressure, title: tr("Memory pressure"), hue: .memory) { formatter.percent($0) },
            HistoryMetric(metric: .cpuTemperature, title: tr("CPU temperature"), hue: .thermal) { formatter.temperature($0) },
            HistoryMetric(metric: .systemPower, title: tr("Power"), hue: .power) { formatter.watts($0) },
            HistoryMetric(metric: .networkDownload, title: tr("Download"), hue: .network) { formatter.rate($0) }
        ]
        if hasBattery {
            metrics.insert(HistoryMetric(metric: .batteryCharge, title: tr("Battery"), hue: .battery) { formatter.percent($0) }, at: 5)
        }
        return metrics
    }
}

/// Periods offered on the History screen, each with a resolution that keeps charts readable.
enum HistoryPeriod: String, CaseIterable, Identifiable {
    case hour, day, week, month

    var id: String { rawValue }

    var duration: TimeInterval {
        switch self {
        case .hour: 3_600
        case .day: 86_400
        case .week: 7 * 86_400
        case .month: 30 * 86_400
        }
    }

    var resolution: HistoryResolution {
        switch self {
        case .hour: .minute
        case .day: .fiveMinutes
        case .week, .month: .hour
        }
    }

    var title: String {
        switch self {
        case .hour: tr("Hour")
        case .day: tr("24 hours")
        case .week: tr("7 days")
        case .month: tr("30 days")
        }
    }
}
