import Foundation
import SensaCore

/// Local, private history of key metrics.
///
/// - Readings are aggregated per minute in memory and written in batches (every 30 s),
///   so recording costs a few milliseconds per minute.
/// - Minute buckets are kept for 7 days, then compacted into hourly buckets; everything older
///   than the user's retention is deleted. Nothing ever leaves the Mac.
public actor HistoryStore: HistoryReading {
    private struct Bucket {
        var minimum: Double
        var maximum: Double
        var total: Double
        var count: Int
    }

    private struct Key: Hashable {
        let metric: String
        let bucket: Int64
    }

    static let minute: Int64 = 60
    static let hour: Int64 = 3_600
    static let minuteRetention: TimeInterval = 7 * 86_400

    private let database: SQLiteDatabase
    private let url: URL?
    private let recordedMetrics: Set<MetricID>
    private let flushInterval: TimeInterval
    private var pending: [Key: Bucket] = [:]
    private var lastFlush = Date()

    /// `url == nil` keeps everything in memory (tests).
    public init(url: URL?, recordedMetrics: [MetricID] = HistoryMetrics.recorded, flushInterval: TimeInterval = 30) throws {
        self.url = url
        if let url { try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true) }
        database = try SQLiteDatabase(url: url)
        self.recordedMetrics = Set(recordedMetrics)
        self.flushInterval = flushInterval
        try database.execute("""
            CREATE TABLE IF NOT EXISTS samples (
                resolution INTEGER NOT NULL, metric TEXT NOT NULL, bucket INTEGER NOT NULL,
                minimum REAL NOT NULL, maximum REAL NOT NULL, total REAL NOT NULL, count INTEGER NOT NULL,
                PRIMARY KEY (resolution, metric, bucket)
            ) WITHOUT ROWID;
            CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp REAL NOT NULL,
                kind TEXT NOT NULL, level INTEGER NOT NULL, value REAL
            );
            CREATE INDEX IF NOT EXISTS events_time ON events(timestamp);
            """)
    }

    /// Default location: `~/Library/Application Support/Sensa/history.sqlite`.
    public static func defaultURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("Sensa", isDirectory: true).appendingPathComponent("history.sqlite")
    }

    // MARK: - Writing

    /// Aggregates readings of recorded metrics; writes when the flush interval has passed.
    public func record(_ readings: [Reading]) throws {
        for reading in readings where recordedMetrics.contains(reading.metric) && reading.value.isFinite {
            let key = Key(metric: reading.metric.rawValue, bucket: Self.bucket(reading.timestamp, size: Self.minute))
            if var bucket = pending[key] {
                bucket.minimum = min(bucket.minimum, reading.value)
                bucket.maximum = max(bucket.maximum, reading.value)
                bucket.total += reading.value
                bucket.count += 1
                pending[key] = bucket
            } else {
                pending[key] = Bucket(minimum: reading.value, maximum: reading.value, total: reading.value, count: 1)
            }
        }
        if Date().timeIntervalSince(lastFlush) >= flushInterval { try flush() }
    }

    public func flush() throws {
        lastFlush = Date()
        guard !pending.isEmpty else { return }
        let rows = pending.map { key, bucket -> [SQLiteValue] in
            [.integer(Self.minute), .text(key.metric), .integer(key.bucket),
             .real(bucket.minimum), .real(bucket.maximum), .real(bucket.total), .integer(Int64(bucket.count))]
        }
        pending.removeAll(keepingCapacity: true)
        try database.run("INSERT INTO samples VALUES (?, ?, ?, ?, ?, ?, ?) " + Self.mergeClause, rows: rows)
    }

    public func log(kind: String, level: HealthLevel, value: Double?, at date: Date = Date()) throws {
        try database.run(
            "INSERT INTO events (timestamp, kind, level, value) VALUES (?, ?, ?, ?)",
            rows: [[.real(date.timeIntervalSince1970), .text(kind), .integer(Int64(level.rawValue)), value.map(SQLiteValue.real) ?? .null]]
        )
    }

    /// Compacts week-old minute buckets into hours and deletes data older than `retentionDays`.
    public func maintain(retentionDays: Int, now: Date = Date()) throws {
        try flush()
        let minuteCutoff = Self.bucket(now.addingTimeInterval(-Self.minuteRetention), size: Self.hour)
        try database.execute("BEGIN")
        do {
            _ = try database.query("""
                INSERT INTO samples
                SELECT \(Self.hour), metric, (bucket / \(Self.hour)) * \(Self.hour), min(minimum), max(maximum), sum(total), sum(count)
                FROM samples WHERE resolution = \(Self.minute) AND bucket < ?
                GROUP BY metric, (bucket / \(Self.hour)) * \(Self.hour)
                """ + " " + Self.mergeClause, [.integer(minuteCutoff)])
            _ = try database.query("DELETE FROM samples WHERE resolution = \(Self.minute) AND bucket < ?", [.integer(minuteCutoff)])
            let retentionCutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
            _ = try database.query("DELETE FROM samples WHERE bucket < ?", [.integer(Int64(retentionCutoff.timeIntervalSince1970))])
            _ = try database.query("DELETE FROM events WHERE timestamp < ?", [.real(retentionCutoff.timeIntervalSince1970)])
            try database.execute("COMMIT")
        } catch {
            try? database.execute("ROLLBACK")
            throw error
        }
    }

    public func deleteAll() throws {
        pending.removeAll()
        try database.execute("DELETE FROM samples; DELETE FROM events; VACUUM;")
    }

    // MARK: - Reading

    public func points(metric: MetricID, from: Date, to: Date, resolution: HistoryResolution) throws -> [HistoryPoint] {
        try flush()
        let step = Int64(resolution.rawValue)
        return try database.query("""
            SELECT (bucket / ?) * ? AS slot, min(minimum), max(maximum), sum(total) / sum(count)
            FROM samples WHERE metric = ? AND bucket >= ? AND bucket < ?
            GROUP BY slot ORDER BY slot
            """, [.integer(step), .integer(step), .text(metric.rawValue),
                  .integer(Int64(from.timeIntervalSince1970)), .integer(Int64(to.timeIntervalSince1970))])
            .compactMap { row in
                guard let slot = row[0].int64, let low = row[1].double, let high = row[2].double, let mean = row[3].double else { return nil }
                return HistoryPoint(date: Date(timeIntervalSince1970: TimeInterval(slot)), minimum: low, maximum: high, average: mean)
            }
    }

    public func events(from: Date, to: Date) throws -> [HistoryEvent] {
        try database.query(
            "SELECT id, timestamp, kind, level, value FROM events WHERE timestamp >= ? AND timestamp < ? ORDER BY timestamp DESC",
            [.real(from.timeIntervalSince1970), .real(to.timeIntervalSince1970)]
        ).compactMap { row in
            guard let id = row[0].int64, let time = row[1].double, let kind = row[2].string, let level = row[3].int64 else { return nil }
            return HistoryEvent(
                id: id, date: Date(timeIntervalSince1970: time), kind: kind,
                level: HealthLevel(rawValue: Int(level)) ?? .attention, value: row[4].double
            )
        }
    }

    public func export(format: HistoryExportFormat, from: Date, to: Date) throws -> Data {
        try flush()
        let rows = try database.query("""
            SELECT metric, bucket, resolution, minimum, maximum, total / count, count
            FROM samples WHERE bucket >= ? AND bucket < ? ORDER BY metric, bucket
            """, [.integer(Int64(from.timeIntervalSince1970)), .integer(Int64(to.timeIntervalSince1970))])
        return HistoryExport.encode(rows.map(HistoryExport.Row.init), format: format)
    }

    public func storageSize() -> Int64 {
        guard let url else { return 0 }
        return ["", "-wal", "-shm"].reduce(Int64(0)) { total, suffix in
            let path = url.path + suffix
            let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.int64Value ?? 0
            return total + size
        }
    }

    // MARK: - Helpers

    private static let mergeClause = """
        ON CONFLICT(resolution, metric, bucket) DO UPDATE SET
        minimum = min(minimum, excluded.minimum), maximum = max(maximum, excluded.maximum),
        total = total + excluded.total, count = count + excluded.count
        """

    static func bucket(_ date: Date, size: Int64) -> Int64 {
        Int64(date.timeIntervalSince1970) / size * size
    }
}

/// CSV / JSON encoding of exported buckets. Pure, testable.
enum HistoryExport {
    struct Row: Encodable, Equatable {
        let metric: String
        let timestamp: Date
        let resolutionSeconds: Int64
        let minimum: Double
        let maximum: Double
        let average: Double
        let samples: Int64

        init(_ values: [SQLiteValue]) {
            metric = values[0].string ?? ""
            timestamp = Date(timeIntervalSince1970: TimeInterval(values[1].int64 ?? 0))
            resolutionSeconds = values[2].int64 ?? 0
            minimum = values[3].double ?? 0
            maximum = values[4].double ?? 0
            average = values[5].double ?? 0
            samples = values[6].int64 ?? 0
        }

        init(metric: String, timestamp: Date, resolutionSeconds: Int64, minimum: Double, maximum: Double, average: Double, samples: Int64) {
            self.metric = metric
            self.timestamp = timestamp
            self.resolutionSeconds = resolutionSeconds
            self.minimum = minimum
            self.maximum = maximum
            self.average = average
            self.samples = samples
        }
    }

    static func encode(_ rows: [Row], format: HistoryExportFormat) -> Data {
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return (try? encoder.encode(rows)) ?? Data("[]".utf8)
        case .csv:
            let formatter = ISO8601DateFormatter()
            var lines = ["metric,timestamp,resolution_seconds,minimum,maximum,average,samples"]
            lines += rows.map { row in
                [row.metric, formatter.string(from: row.timestamp), "\(row.resolutionSeconds)",
                 number(row.minimum), number(row.maximum), number(row.average), "\(row.samples)"].joined(separator: ",")
            }
            return Data((lines.joined(separator: "\n") + "\n").utf8)
        }
    }

    /// Locale-independent decimal point, as CSV consumers expect.
    private static func number(_ value: Double) -> String {
        String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
