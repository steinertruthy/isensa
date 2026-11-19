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

    private func make(temperature: Double = 70, thermal: ThermalLevel = .nominal) -> (FanControlCoordinator, RecordingFanService, AppSettings) {
        let store = MetricsStore(profile: DemoEnvironment.profile(.laptopWithFans))
        let fans = (0..<2).map { FanReading(id: $0, currentRPM: 2_000, minimumRPM: 1_200, maximumRPM: 6_000, targetRPM: nil, isAutomatic: true) }
        store.handle(.fragment(SensorSnapshot(
            timestamp: now, sensors: [], fans: fans, cpuTemperature: temperature, gpuTemperature: nil, systemPower: nil
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
