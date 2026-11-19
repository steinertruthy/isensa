import Foundation
import SensaControl
import SensaCore
import SensaDemo
@testable import SensaFeatures
import SensaMonitoring
import Testing

/// Records every call the coordinator makes to the helper.
private actor RecordingFanService: FanControlService {
    nonisolated let isDemo = true
    var applied: [[FanTarget]] = []
    var heartbeats = 0
    var restores = 0
    var holdsManual = true
    var refuses = false
    var attempts = 0

    func state() -> FanHelperState { .ready(HelperStatus()) }
    func apply(_ targets: [FanTarget]) throws {
        attempts += 1
        if refuses { throw FanControlFailure("SMC refused manual mode on F0Md") }
        applied.append(targets)
    }
    func setRefuses(_ value: Bool) { refuses = value }
    func heartbeat() -> Bool {
        heartbeats += 1
        return holdsManual
    }
    func restoreAutomatic() { restores += 1 }
    func install() {}
    func uninstall() {}
    func dropManual() { holdsManual = false }
}

@MainActor
@Suite("Fan control coordinator")
struct FanControlCoordinatorTests {
    private let now = Date(timeIntervalSince1970: 10_000)

    private func make(
        temperature: Double = 70, hottest: Double? = nil, thermal: ThermalLevel = .nominal
    ) -> (FanControlCoordinator, RecordingFanService, AppSettings) {
        let store = MetricsStore(profile: DemoEnvironment.profile(.laptopWithFans))
        let fans = (0..<2).map { FanReading(id: $0, currentRPM: 2_000, minimumRPM: 1_200, maximumRPM: 6_000, targetRPM: nil, isAutomatic: true) }
        store.handle(.fragment(SensorSnapshot(
            timestamp: now, sensors: [], fans: fans, cpuTemperature: temperature, cpuHottestTemperature: hottest,
            gpuTemperature: nil, systemPower: nil
        )))
        store.handle(.fragment(ThermalSnapshot(timestamp: now, level: thermal, pressure: nil)))
        let settings = AppSettings(defaults: UserDefaults(suiteName: "fan.tests.\(UUID().uuidString)")!)
        let service = RecordingFanService()
        return (FanControlCoordinator(service: service, store: store, settings: settings), service, settings)
    }

    @Test func automaticNeverTalksToTheHelper() async {
        let (coordinator, service, _) = make()
        await coordinator.tick(now: now)
        #expect(await service.applied.isEmpty)
        #expect(await service.restores == 0)
        #expect(coordinator.plan == .system(.userChoice))
    }

    @Test func fixedSpeedAppliesOnceThenKeepsTheLeaseAlive() async {
        let (coordinator, service, settings) = make()
        settings.fanMode = .fixed(fraction: 0.5)
        await coordinator.tick(now: now)
        await coordinator.tick(now: now.addingTimeInterval(2))
        await coordinator.tick(now: now.addingTimeInterval(4))
        #expect(await service.applied == [[FanTarget(index: 0, rpm: 3_600), FanTarget(index: 1, rpm: 3_600)]])
        #expect(await service.heartbeats == 2)
        #expect(coordinator.isManual)
    }

    @Test func reappliesWhenTheHelperDroppedTheSetting() async {
        let (coordinator, service, settings) = make()
        settings.fanMode = .fixed(fraction: 1)
        await coordinator.tick(now: now)
        await service.dropManual()
        await coordinator.tick(now: now.addingTimeInterval(2))
        await coordinator.tick(now: now.addingTimeInterval(4))
        #expect(await service.applied.count == 2)
    }

    @Test func goingBackToAutomaticRestoresOnce() async {
        let (coordinator, service, settings) = make()
        settings.fanMode = .fixed(fraction: 0.5)
        await coordinator.tick(now: now)
        settings.fanMode = .automatic
        await coordinator.tick(now: now.addingTimeInterval(2))
        await coordinator.tick(now: now.addingTimeInterval(4))
        #expect(await service.restores == 1)
        #expect(!coordinator.isManual)
    }

    @Test func aRefusalIsNotRetriedUntilTheUserActs() async {
        let (coordinator, service, settings) = make()
        await service.setRefuses(true)
        settings.fanMode = .fixed(fraction: 0.5)
        await coordinator.tick(now: now)
        await coordinator.tick(now: now.addingTimeInterval(2))
        settings.fanMode = .fixed(fraction: 0.8) // moving the slider is not a new attempt
        await coordinator.tick(now: now.addingTimeInterval(4))
        #expect(await service.attempts == 1)
        #expect(coordinator.problem == .notApplied("SMC refused manual mode on F0Md"))
        #expect(coordinator.plan == .system(.userChoice))

        await service.setRefuses(false)
        await coordinator.retry()
        #expect(await service.attempts == 2)
        #expect(coordinator.isManual)
        #expect(coordinator.problem == nil)
    }

    @Test func switchingModeAfterARefusalTriesAgain() async {
        let (coordinator, service, settings) = make()
        await service.setRefuses(true)
        settings.fanMode = .fixed(fraction: 0.5)
        await coordinator.tick(now: now)
        settings.fanMode = .curve(.performance)
        await coordinator.tick(now: now.addingTimeInterval(2))
        #expect(await service.attempts == 2)
    }

    @Test func curvesFollowTheHottestCoreNotTheMean() async throws {
        let (coordinator, service, settings) = make(temperature: 55, hottest: 90)
        settings.fanMode = .curve(.performance)
        await coordinator.tick(now: now)
        #expect(coordinator.controlTemperature == 90)
        let targets = try #require(await service.applied.last)
        #expect(targets.allSatisfy { $0.rpm == 6_000 }, "90 °C on the hottest core is full speed on Performance")
    }

    @Test func customCurvesDriveTheFans() async throws {
        let (coordinator, service, settings) = make(temperature: 50, hottest: 60)
        settings.fanMode = .custom(FanCurve(points: [.init(40, 0), .init(80, 1)]))
        await coordinator.tick(now: now)
        let targets = try #require(await service.applied.last)
        #expect(targets.allSatisfy { $0.rpm == 3_600 }, "60 °C is halfway: 50% of 1,200–6,000 rpm")
    }

    @Test func changingTheCurveShapeIsNotANewAttempt() {
        #expect(FanControlCoordinator.sameKind(.curve(.quiet), .custom(FanCurve.Preset.quiet.curve)))
        #expect(!FanControlCoordinator.sameKind(.fixed(fraction: 0.5), .custom(FanCurve.Preset.quiet.curve)))
    }

    @Test func curveChoicesMapToModes() {
        #expect(FanCurveChoice(.curve(.performance)) == .performance)
        #expect(FanCurveChoice(.custom(FanCurve.Preset.quiet.curve)) == .custom)
        #expect(FanCurveChoice(.automatic) == nil)
        #expect(FanCurveChoice.custom.preset == nil)
        #expect(FanCurveChoice.quiet.preset == .quiet)
    }

    @Test func customCurveIsRememberedAndRepaired() {
        let defaults = UserDefaults(suiteName: "fan.custom.\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)
        #expect(settings.customFanCurve == FanCurve.Preset.balanced.curve)
        settings.customFanCurve = FanCurve(points: [.init(45, 0.2), .init(75, 0.6), .init(92, 1)])
        #expect(AppSettings(defaults: defaults).customFanCurve == settings.customFanCurve)
        settings.customFanCurve = FanCurve(points: [.init(45, 0.9), .init(75, 0.2)])
        #expect(AppSettings(defaults: defaults).customFanCurve.points.map(\.fraction) == [0.9, 1])
    }

    @Test func thermalPressureHandsControlBack() async {
        let (coordinator, service, settings) = make(thermal: .serious)
        settings.fanMode = .curve(.performance)
        await coordinator.tick(now: now)
        #expect(await service.applied.isEmpty)
        #expect(coordinator.plan == .system(.thermalPressure))
    }

    @Test func suspendRestoresAndPausesUntilResumed() async {
        let (coordinator, service, settings) = make()
        settings.fanMode = .fixed(fraction: 0.5)
        await coordinator.tick(now: now)
        await coordinator.suspend()
        await coordinator.tick(now: now.addingTimeInterval(2))
        #expect(await service.restores == 1)
        #expect(await service.applied.count == 1, "Suspended: nothing is sent")
        coordinator.resume()
        await coordinator.tick(now: now.addingTimeInterval(4))
        #expect(await service.applied.count == 2)
    }
}

@Suite("Fan target wording")
struct FanTargetWordingTests {
    @Test func withinFivePercentIsHoldingTheTarget() {
        // Measured on Mac15,6: 4,609–4,622 rpm for a 4,559 rpm target.
        #expect(FanFormatting.progress(current: 4_622, target: 4_559) == .holding)
        #expect(FanFormatting.progress(current: 4_340, target: 4_559) == .holding)
    }

    @Test func outsideTheToleranceSaysWhichWayItIsGoing() {
        #expect(FanFormatting.progress(current: 0, target: 4_559) == .speedingUp)
        #expect(FanFormatting.progress(current: 6_500, target: 4_559) == .slowingDown)
    }
}

@Suite("History comparison")
struct HistoryComparisonTests {
    private func point(_ seconds: TimeInterval, _ average: Double) -> HistoryPoint {
        HistoryPoint(date: Date(timeIntervalSince1970: seconds), minimum: average, maximum: average, average: average)
    }

    @Test func shiftsThePreviousPeriodOntoTheCurrentAxis() {
        let shifted = HistoryComparison.shifted([point(0, 1), point(60, 2)], by: 3_600)
        #expect(shifted.map(\.date.timeIntervalSince1970) == [3_600, 3_660])
        #expect(shifted.map(\.average) == [1, 2])
    }

    @Test func trendHasAFivePercentDeadBand() {
        #expect(HistoryComparison.trend(current: 0.42, previous: 0.41) == .steady)
        #expect(HistoryComparison.trend(current: 0.20, previous: 0.10) == .higher)
        #expect(HistoryComparison.trend(current: 50, previous: 70) == .lower)
        #expect(HistoryComparison.trend(current: 0, previous: 0) == .steady)
    }

    @Test func linesBreakWhereNothingWasRecorded() {
        let points = [point(0, 1), point(60, 1), point(120, 1), point(3_600, 1), point(3_660, 1)]
        let segments = HistoryComparison.segmented(points, maximumGap: 180).map(\.segment)
        #expect(segments == [0, 0, 0, 1, 1])
    }

    @Test func averageOfNothingIsUnknown() {
        #expect(HistoryComparison.average([]) == nil)
        #expect(HistoryComparison.average([point(0, 2), point(60, 4)]) == 3)
    }
}

@Suite("History metrics")
struct HistoryMetricListTests {
    @Test func everyFanIsRecordedAndShownNextToTheTemperature() {
        #expect(HistoryMetrics.recorded.contains(.fanSpeed(1)))
        let ids = HistoryMetric.all(formatter: MetricFormatter(temperatureUnit: .celsius), hasBattery: true, fanCount: 2).map(\.metric)
        let temperature = ids.firstIndex(of: .cpuTemperature)
        #expect(temperature.map { Array(ids[($0 + 1)...($0 + 2)]) } == [.fanSpeed(0), .fanSpeed(1)])
        #expect(!HistoryMetric.all(formatter: MetricFormatter(temperatureUnit: .celsius), hasBattery: false).map(\.metric).contains(.fanSpeed(0)))
    }
}

@Suite("History time axis")
struct HistoryAxisTests {
    @Test func ticksFallOnRoundHoursAndAvoidTheEdge() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        let end = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 6, minute: 30))!
        let window = end.addingTimeInterval(-86_400)...end
        let hours = HistoryPeriod.day.axisTicks(in: window, calendar: calendar).map { calendar.component(.hour, from: $0) }
        // 06:00 is only 30 minutes from the end, so its label would be cut off.
        #expect(hours == [12, 18, 0])
    }
}
