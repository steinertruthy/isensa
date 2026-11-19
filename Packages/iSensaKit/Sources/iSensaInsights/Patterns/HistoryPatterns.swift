import Foundation
import iSensaCore

/// Something that changed together over a period. Descriptive only: values that move together do
/// not necessarily cause each other, and the wording shown to people says so.
public enum HistoryPattern: Equatable, Sendable {
    /// CPU temperature rose and fell with CPU usage.
    case temperatureFollowsCPU
    /// The CPU ran warm while mostly idle: something else (GPU, charging, surroundings) likely contributed.
    case warmWhileCPUIdle(peakCelsius: Double)
    /// Fans sped up with temperature; `startCelsius` is the typical temperature when they were spinning.
    case fansFollowTemperature(startCelsius: Double?)
    /// Fans did not spin at all during the period.
    case fansStayedOff
    /// The hottest moment, with CPU usage at that time when known.
    case temperaturePeak(celsius: Double, date: Date, cpuUsage: Double?)
}

/// Finds patterns in recorded history. Pure and deterministic.
public enum HistoryPatternFinder {
    /// Fewer aligned samples than this say nothing reliable.
    public static let minimumSamples = 20
    static let strongCorrelation = 0.6
    static let weakCorrelation = 0.2
    /// Below this, a warm CPU is unremarkable.
    static let warmThreshold = 70.0
    /// CPU usage (fraction) considered mostly idle.
    static let idleUsage = 0.25
    /// A fan below this is considered stopped.
    static let spinningRPM = 100.0

    /// At most `limit` patterns, most informative first.
    public static func patterns(in series: [MetricID: [HistoryPoint]], limit: Int = 3) -> [HistoryPattern] {
        let temperature = series[.cpuTemperature] ?? []
        let usage = series[.cpuUsage] ?? []
        let fan = series[.fanSpeed(0)] ?? []
        var found: [HistoryPattern] = []

        let temperatureAndUsage = aligned(temperature, usage)
        if temperatureAndUsage.count >= minimumSamples, let correlation = pearson(temperatureAndUsage) {
            let peak = temperature.map(\.maximum).max() ?? 0
            let meanUsage = temperatureAndUsage.map(\.1).reduce(0, +) / Double(temperatureAndUsage.count)
            if correlation >= strongCorrelation {
                found.append(.temperatureFollowsCPU)
            } else if correlation < weakCorrelation, peak >= warmThreshold, meanUsage < idleUsage {
                found.append(.warmWhileCPUIdle(peakCelsius: peak))
            }
        }

        if fan.count >= minimumSamples {
            if (fan.map(\.maximum).max() ?? 0) < spinningRPM {
                found.append(.fansStayedOff)
            } else {
                let fanAndTemperature = aligned(fan, temperature)
                if fanAndTemperature.count >= minimumSamples, let correlation = pearson(fanAndTemperature), correlation >= strongCorrelation - 0.1 {
                    let spinning = fanAndTemperature.filter { $0.0 >= spinningRPM }.map(\.1)
                    found.append(.fansFollowTemperature(startCelsius: percentile(spinning, 0.1)?.rounded()))
                }
            }
        }

        if temperature.count >= minimumSamples, let hottest = temperature.max(by: { $0.maximum < $1.maximum }) {
            let usageThen = usage.first { abs($0.date.timeIntervalSince(hottest.date)) < 1 }?.average
            found.append(.temperaturePeak(celsius: hottest.maximum, date: hottest.date, cpuUsage: usageThen))
        }
        return Array(found.prefix(limit))
    }

    /// A low percentile rather than the minimum, so one odd sample does not decide.
    static func percentile(_ values: [Double], _ fraction: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        return sorted[min(Int(Double(sorted.count - 1) * fraction), sorted.count - 1)]
    }

    /// Pairs averages that share a bucket.
    static func aligned(_ first: [HistoryPoint], _ second: [HistoryPoint]) -> [(Double, Double)] {
        let byDate = Dictionary(second.map { ($0.date, $0.average) }, uniquingKeysWith: { lhs, _ in lhs })
        return first.compactMap { point in byDate[point.date].map { (point.average, $0) } }
    }

    /// Pearson correlation; `nil` when either series is constant.
    static func pearson(_ pairs: [(Double, Double)]) -> Double? {
        guard pairs.count > 2 else { return nil }
        let count = Double(pairs.count)
        let meanX = pairs.map(\.0).reduce(0, +) / count
        let meanY = pairs.map(\.1).reduce(0, +) / count
        var covariance = 0.0, varianceX = 0.0, varianceY = 0.0
        for (x, y) in pairs {
            covariance += (x - meanX) * (y - meanY)
            varianceX += (x - meanX) * (x - meanX)
            varianceY += (y - meanY) * (y - meanY)
        }
        guard varianceX > 0, varianceY > 0 else { return nil }
        return covariance / (varianceX * varianceY).squareRoot()
    }
}
