import Foundation

/// One aggregated point of a stored series.
public struct HistoryPoint: Sendable, Hashable, Identifiable {
    public let date: Date
    public let minimum: Double
    public let maximum: Double
    public let average: Double

    public init(date: Date, minimum: Double, maximum: Double, average: Double) {
        self.date = date
        self.minimum = minimum
        self.maximum = maximum
        self.average = average
    }

    public var id: Date { date }
}

/// Bucket size used when reading history back.
public enum HistoryResolution: Int, Sendable, CaseIterable {
    case minute = 60
    case fiveMinutes = 300
    case hour = 3_600
    case day = 86_400
}

/// Something worth remembering next to the numbers (an alert that fired).
public struct HistoryEvent: Sendable, Hashable, Identifiable {
    public let id: Int64
    public let date: Date
    /// Stable identifier of the event type (e.g. an alert kind's raw value).
    public let kind: String
    public let level: HealthLevel
    /// The measured value that triggered the event, in the kind's canonical unit.
    public let value: Double?

    public init(id: Int64, date: Date, kind: String, level: HealthLevel, value: Double?) {
        self.id = id
        self.date = date
        self.kind = kind
        self.level = level
        self.value = value
    }
}

public enum HistoryExportFormat: String, Sendable, CaseIterable {
    case csv, json
}

/// Read side of the history store, as seen by the interface.
public protocol HistoryReading: Sendable {
    func points(metric: MetricID, from: Date, to: Date, resolution: HistoryResolution) async throws -> [HistoryPoint]
    func events(from: Date, to: Date) async throws -> [HistoryEvent]
    func export(format: HistoryExportFormat, from: Date, to: Date) async throws -> Data
    func deleteAll() async throws
    /// Size of the database on disk, in bytes.
    func storageSize() async -> Int64
}

/// Metrics worth keeping over time. Per-core and per-sensor series stay live-only.
public enum HistoryMetrics {
    /// Fans recorded per Mac; current models have at most two.
    public static let maximumFans = 4

    public static let recorded: [MetricID] = [
        .cpuUsage, .gpuUsage, .memoryUsed, .memoryPressure, .cpuTemperature, .gpuTemperature,
        .systemPower, .batteryCharge, .networkDownload, .networkUpload, .diskRead, .diskWrite
    ] + (0..<maximumFans).map(MetricID.fanSpeed)
}
