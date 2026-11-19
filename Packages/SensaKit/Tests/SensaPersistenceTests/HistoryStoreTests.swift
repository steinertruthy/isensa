import Foundation
import SensaCore
@testable import SensaPersistence
import Testing

@Suite("History store")
struct HistoryStoreTests {
    private func reading(_ metric: MetricID, _ value: Double, at seconds: TimeInterval) -> Reading {
        Reading(metric: metric, value: value, unit: .fraction, timestamp: Date(timeIntervalSince1970: seconds), provenance: .system(api: "test"))
    }

    @Test func aggregatesReadingsPerMinute() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        try await store.record([reading(.cpuUsage, 0.2, at: 60), reading(.cpuUsage, 0.6, at: 90), reading(.cpuUsage, 0.4, at: 130)])
        let points = try await store.points(metric: .cpuUsage, from: Date(timeIntervalSince1970: 0), to: Date(timeIntervalSince1970: 600), resolution: .minute)
        #expect(points.count == 2)
        #expect(points[0].minimum == 0.2)
        #expect(points[0].maximum == 0.6)
        #expect(abs(points[0].average - 0.4) < 1e-9)
        #expect(points[1].average == 0.4)
    }

    @Test func ignoresMetricsThatAreNotRecorded() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        try await store.record([reading(.cpuCoreUsage(3), 0.9, at: 60)])
        let points = try await store.points(metric: .cpuCoreUsage(3), from: .distantPast, to: .distantFuture, resolution: .minute)
        #expect(points.isEmpty)
    }

    @Test func mergesBucketsAcrossFlushes() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        try await store.record([reading(.cpuUsage, 0.1, at: 60)])
        try await store.record([reading(.cpuUsage, 0.9, at: 61)])
        let points = try await store.points(metric: .cpuUsage, from: .distantPast, to: .distantFuture, resolution: .minute)
        #expect(points.count == 1)
        #expect(points[0].minimum == 0.1)
        #expect(points[0].maximum == 0.9)
        #expect(abs(points[0].average - 0.5) < 1e-9)
    }

    @Test func compactsOldMinutesIntoHoursAndAppliesRetention() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        let now = Date(timeIntervalSince1970: 100 * 86_400)
        let tenDaysAgo = now.timeIntervalSince1970 - 10 * 86_400
        let fortyDaysAgo = now.timeIntervalSince1970 - 40 * 86_400
        try await store.record([
            reading(.cpuUsage, 0.2, at: tenDaysAgo), reading(.cpuUsage, 0.4, at: tenDaysAgo + 120),
            reading(.cpuUsage, 0.9, at: fortyDaysAgo), reading(.cpuUsage, 0.5, at: now.timeIntervalSince1970 - 60)
        ])
        try await store.maintain(retentionDays: 30, now: now)
        let old = try await store.points(metric: .cpuUsage, from: .distantPast, to: now.addingTimeInterval(-8 * 86_400), resolution: .hour)
        #expect(old.count == 1, "Ten-day-old minutes become one hourly bucket; forty-day-old data is deleted")
        #expect(abs(old[0].average - 0.3) < 1e-9)
        let recent = try await store.points(metric: .cpuUsage, from: now.addingTimeInterval(-3_600), to: now, resolution: .minute)
        #expect(recent.count == 1, "Recent minutes are untouched")
    }

    @Test func logsEventsAndDeletesEverything() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        try await store.log(kind: "highTemperature", level: .attention, value: 97, at: Date(timeIntervalSince1970: 1_000))
        var events = try await store.events(from: .distantPast, to: .distantFuture)
        #expect(events.first?.kind == "highTemperature")
        #expect(events.first?.value == 97)
        try await store.deleteAll()
        events = try await store.events(from: .distantPast, to: .distantFuture)
        #expect(events.isEmpty)
    }

    @Test func exportsCSVAndJSON() async throws {
        let store = try HistoryStore(url: nil, flushInterval: 0)
        try await store.record([reading(.cpuUsage, 0.25, at: 60)])
        let csvData = try await store.export(format: .csv, from: .distantPast, to: .distantFuture)
        let csv = String(bytes: csvData, encoding: .utf8) ?? ""
        #expect(csv.hasPrefix("metric,timestamp,resolution_seconds,minimum,maximum,average,samples\n"))
        #expect(csv.contains("cpu.usage,1970-01-01T00:01:00Z,60,0.2500,0.2500,0.2500,1"))
        let jsonData = try await store.export(format: .json, from: .distantPast, to: .distantFuture)
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
        #expect(json?.first?["metric"] as? String == "cpu.usage")
        #expect(json?.first?["resolution_seconds"] as? Int == 60)
    }

    @Test func persistsOnDisk() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sensa-\(UUID().uuidString)/history.sqlite")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        do {
            let store = try HistoryStore(url: url, flushInterval: 0)
            try await store.record([reading(.cpuUsage, 0.3, at: 60)])
        }
        let reopened = try HistoryStore(url: url)
        let points = try await reopened.points(metric: .cpuUsage, from: .distantPast, to: .distantFuture, resolution: .minute)
        #expect(points.count == 1)
        #expect(await reopened.storageSize() > 0)
    }
}
