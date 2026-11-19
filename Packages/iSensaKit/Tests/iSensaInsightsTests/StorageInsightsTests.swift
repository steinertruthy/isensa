import Foundation
import iSensaCore
@testable import iSensaInsights
import Testing

@Suite("Storage trend")
struct StorageTrendTests {
    private func points(days: Int, perDay: Double, start: Double = 400e9, every hours: Int = 6) -> [HistoryPoint] {
        stride(from: 0, through: days * 24, by: hours).map { hour in
            let value = start + perDay * Double(hour) / 24
            return HistoryPoint(date: Date(timeIntervalSince1970: Double(hour) * 3_600), minimum: value, maximum: value, average: value)
        }
    }

    @Test func growthAndForecast() throws {
        let trend = try #require(StorageTrend.compute(usedSpace: points(days: 7, perDay: 2e9), available: 30e9.uint64))
        #expect(abs(trend.growthPerDay - 2e9) < 1e3)
        #expect(abs((trend.daysUntilFull ?? 0) - 15) < 0.01)
    }

    @Test func stableOrShrinkingDisksHaveNoForecast() throws {
        #expect(try #require(StorageTrend.compute(usedSpace: points(days: 5, perDay: 50e6), available: 10e9.uint64)).daysUntilFull == nil)
        #expect(try #require(StorageTrend.compute(usedSpace: points(days: 5, perDay: -3e9), available: 10e9.uint64)).daysUntilFull == nil)
        #expect(try #require(StorageTrend.compute(usedSpace: points(days: 5, perDay: 0.2e9), available: 400e9.uint64)).daysUntilFull == nil,
                "Beyond a year a projection means nothing")
    }

    @Test func needsTwoDaysOfHistory() {
        #expect(StorageTrend.compute(usedSpace: points(days: 1, perDay: 5e9), available: 10e9.uint64) == nil)
        #expect(StorageTrend.compute(usedSpace: [], available: 10e9.uint64) == nil)
    }

    @Test func ssdWritesPerDayFromTheLifetimeCounter() {
        let written = points(days: 3, perDay: 40e9, start: 11e12)
        #expect(abs((StorageTrend.writesPerDay(lifetimeWritten: written) ?? 0) - 40e9) < 1e3)
        #expect(StorageTrend.writesPerDay(lifetimeWritten: Array(written.prefix(2))) == nil, "Less than half a day")
        #expect(StorageTrend.writesPerDay(lifetimeWritten: points(days: 2, perDay: -1e9, start: 11e12)) == nil, "A different drive")
    }
}

@Suite("Storage alerts")
struct StorageAlertTests {
    private func snapshot(available: Double) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        snapshot.storage = StorageSnapshot(timestamp: Date(), volumes: [VolumeInfo(
            id: "root", name: "Macintosh HD", mountPoint: "/", totalCapacity: 500_000_000_000, availableCapacity: available.uint64,
            isInternal: true, isRemovable: false, isRoot: true
        )], readRate: nil, writeRate: nil)
        return snapshot
    }

    private func run(_ engine: inout AlertEngine, available: Double, at minutes: Double) -> [AlertKind] {
        var configuration = AlertConfiguration()
        configuration.isEnabled = true
        return engine.evaluate(
            snapshot(available: available), capabilities: CapabilityMap(), configuration: configuration,
            now: Date(timeIntervalSince1970: minutes * 60)
        ).map(\.kind)
    }

    @Test func firesWhenFreeSpaceDropsFastWithinTheWindow() {
        var engine = AlertEngine()
        #expect(run(&engine, available: 200e9, at: 0).isEmpty)
        #expect(run(&engine, available: 195e9, at: 10).isEmpty)
        #expect(run(&engine, available: 189e9, at: 20) == [.storageFillingFast])
        #expect(run(&engine, available: 185e9, at: 25).isEmpty, "Fires once while active")
    }

    @Test func slowDeclineDoesNotFire() {
        var engine = AlertEngine()
        for minute in stride(from: 0.0, through: 240, by: 10) {
            #expect(run(&engine, available: 200e9 - minute * 0.2e9, at: minute).isEmpty, "8 GB over 4 hours, never 10 GB in 30 minutes")
        }
    }

    @Test func olderPreferencesKeepTheirValuesAndGainNewRules() throws {
        let saved = Data(#"{"isEnabled":true,"highTemperature":{"isEnabled":false,"threshold":88},"sustainedSeconds":120}"#.utf8)
        let configuration = try JSONDecoder().decode(AlertConfiguration.self, from: saved)
        #expect(configuration.isEnabled)
        #expect(configuration.highTemperature == .init(isEnabled: false, threshold: 88))
        #expect(configuration.sustainedSeconds == 120)
        #expect(configuration.storageFillingFast == AlertConfiguration().storageFillingFast)
        let roundTrip = try JSONDecoder().decode(AlertConfiguration.self, from: JSONEncoder().encode(configuration))
        #expect(roundTrip == configuration)
    }
}

private extension Double {
    var uint64: UInt64 { UInt64(self) }
}
