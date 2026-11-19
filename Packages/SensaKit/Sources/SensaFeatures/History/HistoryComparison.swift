import Foundation
import SensaCore

/// Pure helpers for comparing a period with the one before it.
enum HistoryComparison {
    enum Trend: Equatable {
        case higher, lower, steady
    }

    /// Averages within this share of each other count as about the same.
    static let steadyTolerance = 0.05

    static func average(_ points: [HistoryPoint]) -> Double? {
        guard !points.isEmpty else { return nil }
        return points.map(\.average).reduce(0, +) / Double(points.count)
    }

    /// Moves the previous period onto the current period's time axis.
    static func shifted(_ points: [HistoryPoint], by interval: TimeInterval) -> [HistoryPoint] {
        points.map { HistoryPoint(date: $0.date.addingTimeInterval(interval), minimum: $0.minimum, maximum: $0.maximum, average: $0.average) }
    }

    /// A point tagged with the unbroken stretch of data it belongs to.
    struct SegmentedPoint: Identifiable {
        let segment: Int
        let point: HistoryPoint
        var id: Date { point.date }
    }

    /// Splits a series wherever samples are missing for longer than `maximumGap`, so charts break
    /// the line instead of drawing across time when nothing was recorded (e.g. Sensa was closed).
    static func segmented(_ points: [HistoryPoint], maximumGap: TimeInterval) -> [SegmentedPoint] {
        var segment = 0
        var previous: Date?
        return points.map { point in
            if let previous, point.date.timeIntervalSince(previous) > maximumGap { segment += 1 }
            previous = point.date
            return SegmentedPoint(segment: segment, point: point)
        }
    }

    static func trend(current: Double, previous: Double) -> Trend {
        let scale = max(abs(current), abs(previous))
        guard scale > 0 else { return .steady }
        let difference = (current - previous) / scale
        if abs(difference) <= steadyTolerance { return .steady }
        return difference > 0 ? .higher : .lower
    }
}
