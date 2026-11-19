import Foundation
import iSensaCore

/// How the startup disk's used space and the SSD's writes evolve, from recorded history. Pure.
///
/// Projections are estimates: they extend the recent pace in a straight line and say so.
/// Apple does not publish an endurance rating (TBW) for its SSDs, so no lifespan is derived from
/// the write rate — wear itself is what the drive reports in SMART.
public struct StorageTrend: Sendable, Equatable {
    /// Least-squares slope of used space, bytes per day (negative when space is being freed).
    public let growthPerDay: Double
    /// Days until the disk is full at that pace; `nil` when it is not filling up meaningfully.
    public let daysUntilFull: Double?
    /// Period the estimate is based on.
    public let span: TimeInterval

    /// Less history than this gives a slope dominated by a single download or cleanup.
    public static let minimumSpan: TimeInterval = 2 * 86_400
    /// Below this pace the disk is considered stable.
    public static let stableGrowthPerDay: Double = 100_000_000
    /// Beyond this a projection means nothing.
    public static let maximumForecastDays: Double = 365

    public static func compute(usedSpace points: [HistoryPoint], available: UInt64) -> StorageTrend? {
        guard let first = points.first?.date, let last = points.last?.date, last.timeIntervalSince(first) >= minimumSpan else { return nil }
        let xs = points.map { $0.date.timeIntervalSince(first) / 86_400 }
        let ys = points.map(\.average)
        let count = Double(points.count)
        let meanX = xs.reduce(0, +) / count, meanY = ys.reduce(0, +) / count
        let variance = xs.reduce(0) { $0 + ($1 - meanX) * ($1 - meanX) }
        guard variance > 0 else { return nil }
        let covariance = zip(xs, ys).reduce(0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let slope = covariance / variance
        var days: Double?
        if slope >= stableGrowthPerDay {
            let projection = Double(available) / slope
            if projection <= maximumForecastDays { days = projection }
        }
        return StorageTrend(growthPerDay: slope, daysUntilFull: days, span: last.timeIntervalSince(first))
    }

    /// Average bytes written per day to the SSD, from its lifetime counter. `nil` with less than
    /// half a day of history, or when the counter went backwards (a different drive).
    public static func writesPerDay(lifetimeWritten points: [HistoryPoint]) -> Double? {
        guard let first = points.first, let last = points.last else { return nil }
        let span = last.date.timeIntervalSince(first.date)
        guard span >= 43_200, last.maximum >= first.minimum else { return nil }
        return (last.maximum - first.minimum) / (span / 86_400)
    }
}
