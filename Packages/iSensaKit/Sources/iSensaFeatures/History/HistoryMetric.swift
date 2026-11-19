import Foundation
import iSensaCore
import iSensaDesign

/// How each recorded metric is titled, colored and formatted on the History screen.
struct HistoryMetric: Identifiable {
    let metric: MetricID
    let title: String
    let hue: Hue
    /// Converts a stored value to the displayed one.
    let format: (Double) -> String

    var id: MetricID { metric }

    static func all(formatter: MetricFormatter, hasBattery: Bool, fanCount: Int = 0) -> [HistoryMetric] {
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
        let fans = (0..<min(fanCount, HistoryMetrics.maximumFans)).map { index in
            HistoryMetric(metric: .fanSpeed(index), title: tr("Fan %@", "\(index + 1)"), hue: .fans) { formatter.rpm($0) }
        }
        // Fans sit next to the temperature they respond to.
        if let temperature = metrics.firstIndex(where: { $0.metric == .cpuTemperature }) {
            metrics.insert(contentsOf: fans, at: temperature + 1)
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

    /// Spacing of the time axis ticks.
    var axisStep: TimeInterval {
        switch self {
        case .hour: 15 * 60
        case .day: 6 * 3_600
        case .week: 86_400
        case .month: 7 * 86_400
        }
    }

    /// Ticks on round multiples of `axisStep` (in the current time zone), leaving out any that would
    /// sit so close to the end that its label is cut off.
    func axisTicks(in window: ClosedRange<Date>, calendar: Calendar = .current) -> [Date] {
        let offset = TimeInterval(calendar.timeZone.secondsFromGMT(for: window.lowerBound))
        let start = ((window.lowerBound.timeIntervalSince1970 + offset) / axisStep).rounded(.up) * axisStep - offset
        return stride(from: start, through: window.upperBound.timeIntervalSince1970 - axisStep * 0.35, by: axisStep)
            .map(Date.init(timeIntervalSince1970:))
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
