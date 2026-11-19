import Foundation
@testable import iSensaControl
import iSensaCore
import Testing

private let testLimits = [FanLimits(index: 0, minimumRPM: 2_317, maximumRPM: 6_800), FanLimits(index: 1, minimumRPM: 2_317, maximumRPM: 6_800)]

@Suite("Fan command validation")
struct ValidatorTests {
    @Test func clampsIntoTheFanRange() throws {
        let result = try FanCommandValidator.validate([FanTarget(index: 0, rpm: 100), FanTarget(index: 1, rpm: 99_000)], limits: testLimits)
        #expect(result == [FanTarget(index: 0, rpm: 2_317), FanTarget(index: 1, rpm: 6_800)])
    }

    @Test func neverAcceptsZeroOrInvalidSpeeds() {
        #expect(throws: FanCommandError.invalidSpeed(0)) { try FanCommandValidator.validate([FanTarget(index: 0, rpm: 0)], limits: testLimits) }
        #expect(throws: FanCommandError.invalidSpeed(0)) { try FanCommandValidator.validate([FanTarget(index: 0, rpm: .nan)], limits: testLimits) }
        #expect(throws: FanCommandError.invalidSpeed(0)) { try FanCommandValidator.validate([FanTarget(index: 0, rpm: -1)], limits: testLimits) }
    }

    @Test func rejectsUnknownDuplicateAndEmptyRequests() {
        #expect(throws: FanCommandError.unknownFan(2)) { try FanCommandValidator.validate([FanTarget(index: 2, rpm: 3_000)], limits: testLimits) }
        #expect(throws: FanCommandError.duplicateFan(0)) {
            try FanCommandValidator.validate([FanTarget(index: 0, rpm: 3_000), FanTarget(index: 0, rpm: 4_000)], limits: testLimits)
        }
        #expect(throws: FanCommandError.empty) { try FanCommandValidator.validate([], limits: testLimits) }
    }

    @Test func refusesImplausibleLimits() {
        let broken = [FanLimits(index: 0, minimumRPM: 0, maximumRPM: 6_800)]
        #expect(throws: FanCommandError.invalidLimits(0)) { try FanCommandValidator.validate([FanTarget(index: 0, rpm: 3_000)], limits: broken) }
        #expect(!FanLimits(index: 0, minimumRPM: 3_000, maximumRPM: 2_000).isValid)
        #expect(!FanLimits(index: 0, minimumRPM: 1_000, maximumRPM: 90_000).isValid)
    }

    @Test func fractionZeroIsTheMinimumNotOff() {
        #expect(testLimits[0].rpm(atFraction: 0) == 2_317)
        #expect(testLimits[0].rpm(atFraction: 1) == 6_800)
        #expect(testLimits[0].rpm(atFraction: -3) == 2_317)
    }
}

@Suite("Fan curves")
struct CurveTests {
    @Test func interpolatesLinearlyAndIsFlatBeyondTheEnds() {
        let curve = FanCurve(points: [.init(60, 0), .init(80, 1)])
        #expect(curve.fraction(at: 40) == 0)
        #expect(curve.fraction(at: 70) == 0.5)
        #expect(curve.fraction(at: 100) == 1)
    }

    @Test func everyPresetReachesFullSpeedBeforeThrottlingTemperatures() {
        for preset in FanCurve.Preset.allCases {
            #expect(preset.curve.fraction(at: 98) == 1, "\(preset)")
        }
    }
}

@Suite("Fan control planner")
struct PlannerTests {
    private func plan(
        _ planner: inout FanControlPlanner, _ mode: FanMode, _ temperature: Double?, age: TimeInterval = 1, thermal: ThermalLevel? = .nominal,
        at seconds: TimeInterval = 0
    ) -> FanPlan {
        planner.plan(
            mode: mode, temperature: temperature, sampleAge: age, thermalLevel: thermal, limits: testLimits,
            now: Date(timeIntervalSince1970: seconds)
        )
    }

    @Test func automaticAndSafetyConditionsHandControlToMacOS() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .automatic, 70) == .system(.userChoice))
        #expect(plan(&planner, .curve(.performance), nil) == .system(.noTemperature))
        #expect(plan(&planner, .curve(.performance), 70, age: 60) == .system(.noTemperature), "Stale readings count as missing")
        #expect(plan(&planner, .fixed(fraction: 1), 70, thermal: .serious) == .system(.thermalPressure))
        #expect(plan(&planner, .fixed(fraction: 0.2), 92) == .system(.tooHotForFixedSpeed))
        #expect(planner.plan(mode: .fixed(fraction: 1), temperature: 70, sampleAge: 1, thermalLevel: .nominal, limits: [], now: Date()) == .system(.noLimits))
    }

    @Test func tooHotForFixedSpeedUsesHysteresis() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .fixed(fraction: 0.3), 91) == .system(.tooHotForFixedSpeed))
        #expect(plan(&planner, .fixed(fraction: 0.3), 88) == .system(.tooHotForFixedSpeed), "Stays with macOS inside the band")
        guard case .manual = plan(&planner, .fixed(fraction: 0.3), 86) else { Issue.record("Should resume below the band"); return }
        guard case .manual = plan(&planner, .fixed(fraction: 0.3), 89) else { Issue.record("Below the ceiling again"); return }
    }

    @Test func fixedSpeedTargetsEveryFan() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .fixed(fraction: 1), 92) == .manual([FanTarget(index: 0, rpm: 6_800), FanTarget(index: 1, rpm: 6_800)]))
    }

    @Test func curveQuietZoneUsesHysteresis() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .curve(.balanced), 76) == .system(.coolEnough), "Light use stays with macOS")
        #expect(plan(&planner, .curve(.balanced), 81) == .system(.coolEnough))
        guard case .manual = plan(&planner, .curve(.balanced), 83) else { Issue.record("Should take control above 82 °C"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 80) else { Issue.record("Should keep control inside the hysteresis band"); return }
        let delay = FanControlPlanner.quietZoneDelay
        guard case .manual = plan(&planner, .curve(.balanced), 78, at: 10) else { Issue.record("Cool, but not for long enough"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 77, at: 10 + delay - 1) else { Issue.record("Still inside the delay"); return }
        #expect(plan(&planner, .curve(.balanced), 77, at: 10 + delay) == .system(.coolEnough))
        #expect(plan(&planner, .curve(.balanced), 80, at: 10 + delay + 2) == .system(.coolEnough), "Back with macOS until the edge")
    }

    @Test func steadyLoadAtTheEdgeKeepsControlInsteadOfSwitching() {
        // Measured on an M3 Pro: with every core busy the control temperature wandered 77–83 °C.
        var planner = FanControlPlanner()
        let delay = FanControlPlanner.quietZoneDelay
        guard case .manual = plan(&planner, .curve(.balanced), 82, at: 0) else { Issue.record("Takes control at the edge"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 78, at: 10) else { Issue.record("Brief dip"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 80, at: 30) else { Issue.record("Back inside the band"); return }
        // The dip before 30 s no longer counts: the delay starts again from the next dip.
        guard case .manual = plan(&planner, .curve(.balanced), 78, at: 40) else { Issue.record("New dip"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 78, at: 10 + delay) else { Issue.record("Timer restarted at 40 s"); return }
        #expect(plan(&planner, .curve(.balanced), 78, at: 40 + delay) == .system(.coolEnough))
    }

    @Test func safetyHandsBackAtOnceDespiteTheQuietZoneDelay() {
        var planner = FanControlPlanner()
        guard case .manual = plan(&planner, .curve(.balanced), 85, at: 0) else { Issue.record("Takes control"); return }
        #expect(plan(&planner, .curve(.balanced), 85, thermal: .serious, at: 2) == .system(.thermalPressure))
        guard case .manual = plan(&planner, .curve(.balanced), 85, at: 4) else { Issue.record("Retakes control"); return }
        #expect(plan(&planner, .curve(.balanced), nil, at: 6) == .system(.noTemperature))
        guard case .manual = plan(&planner, .curve(.balanced), 85, at: 8) else { Issue.record("Retakes control"); return }
        #expect(plan(&planner, .automatic, 85, at: 10) == .system(.userChoice))
    }

    @Test func curveSpeedsMoveInTenPercentStepsRoundedUp() {
        #expect(FanControlPlanner.stepped(0) == 0)
        #expect(abs(FanControlPlanner.stepped(0.31) - 0.4) < 1e-9)
        #expect(abs(FanControlPlanner.stepped(0.3) - 0.3) < 1e-9)
        #expect(FanControlPlanner.stepped(0.99) == 1)
    }

    @Test func speedsUpAtOnceButSlowsDownGradually() throws {
        var planner = FanControlPlanner()
        let hot = plan(&planner, .curve(.performance), 92)
        #expect(hot == .manual([FanTarget(index: 0, rpm: 6_800), FanTarget(index: 1, rpm: 6_800)]))
        // Sudden drop to 40 °C: one step of at most 10 % of the range.
        guard case let .manual(targets) = plan(&planner, .curve(.performance), 40) else { Issue.record("Expected manual"); return }
        let fraction = (targets[0].rpm - 2_317) / (6_800 - 2_317)
        #expect(abs(fraction - 0.9) < 0.0001)
    }
}

@Suite("Helper safety controller")
struct SafetyControllerTests {
    final class FakeFans: FanHardware {
        var manual: [FanTarget]?
        var restores = 0
        var writeCount = 0
        var failWrites = false

        func limits() throws -> [FanLimits] { testLimits }
        func setManual(_ targets: [FanTarget]) throws {
            if failWrites { throw FanControlFailure("write failed") }
            manual = targets
        }
        func restoreAutomatic() throws {
            manual = nil
            restores += 1
        }
    }

    private let start = Date(timeIntervalSince1970: 1_000)

    @Test func startingRestoresAutomaticEvenWithoutAKnownOverride() {
        let fans = FakeFans()
        let controller = FanSafetyController(hardware: fans)
        controller.start()
        #expect(fans.restores == 1)
        #expect(controller.status.lastRestore == .helperStarted)
    }

    @Test func appliesValidatedTargets() throws {
        let fans = FakeFans()
        let controller = FanSafetyController(hardware: fans)
        try controller.apply([FanTarget(index: 0, rpm: 50_000)], now: start)
        #expect(fans.manual == [FanTarget(index: 0, rpm: 6_800)])
        #expect(controller.status.isManual)
    }

    @Test func leaseExpiresWithoutHeartbeat() throws {
        let fans = FakeFans()
        let controller = FanSafetyController(hardware: fans, leaseDuration: 10)
        try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start)
        controller.tick(now: start.addingTimeInterval(8), thermalPressureIsHigh: false)
        #expect(controller.heartbeat(now: start.addingTimeInterval(8)))
        controller.tick(now: start.addingTimeInterval(16), thermalPressureIsHigh: false)
        #expect(fans.manual != nil, "Heartbeat renewed the lease")
        controller.tick(now: start.addingTimeInterval(18.1), thermalPressureIsHigh: false)
        #expect(fans.manual == nil)
        #expect(controller.status.lastRestore == .leaseExpired)
        #expect(!controller.heartbeat(now: start.addingTimeInterval(19)))
    }

    @Test func disconnectAndStopRestoreAutomatic() throws {
        let fans = FakeFans()
        let controller = FanSafetyController(hardware: fans)
        try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start)
        controller.clientDisconnected()
        #expect(fans.manual == nil)
        #expect(controller.status.lastRestore == .clientDisconnected)
        controller.stopping()
        #expect(controller.status.lastRestore == .helperStopping)
    }

    @Test func thermalPressureRestoresAndBlocksUntilItHasCleared() throws {
        let fans = FakeFans()
        let controller = FanSafetyController(hardware: fans, thermalCooldown: 30)
        try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start)
        controller.tick(now: start.addingTimeInterval(1), thermalPressureIsHigh: true)
        #expect(fans.manual == nil)
        #expect(controller.status.lastRestore == .thermalPressure)
        #expect(throws: FanSafetyError.thermalGuard) { try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start.addingTimeInterval(2)) }
        controller.tick(now: start.addingTimeInterval(3), thermalPressureIsHigh: false)
        controller.tick(now: start.addingTimeInterval(20), thermalPressureIsHigh: false)
        #expect(controller.status.thermalGuardActive, "Still cooling down")
        controller.tick(now: start.addingTimeInterval(34), thermalPressureIsHigh: false)
        #expect(!controller.status.thermalGuardActive)
        try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start.addingTimeInterval(35))
    }

    @Test func aFailedWriteRestoresAutomatic() {
        let fans = FakeFans()
        fans.failWrites = true
        let controller = FanSafetyController(hardware: fans)
        #expect(throws: FanSafetyError.self) { try controller.apply([FanTarget(index: 0, rpm: 3_000)], now: start) }
        #expect(fans.restores == 1)
        #expect(!controller.status.isManual)
    }
}

@Suite("Helper installation script")
struct InstallScriptTests {
    private let hash = String(repeating: "ab", count: 20)

    @Test func verifiesTheCopiedHelperBeforeRegisteringIt() throws {
        let script = try HelperInstallScript.install(bundledHelper: "/Applications/iSensa.app/x", helperCDHash: hash, clientCDHash: hash)
        let copy = try #require(script.range(of: "/bin/cp "))
        let verify = try #require(script.range(of: "codesign --verify -R '=cdhash H\"\(hash)\"'"))
        let bootstrap = try #require(script.range(of: "launchctl bootstrap system"))
        #expect(copy.lowerBound < verify.lowerBound && verify.lowerBound < bootstrap.lowerBound)
        #expect(script.contains("<string>--client-cdhash</string>"))
        #expect(script.contains("<key>RunAtLoad</key><true/>"))
    }

    @Test func removesTheJobInstalledUnderTheOldName() throws {
        let legacy = "launchctl bootout system/app.sensa.Sensa.helper"
        let install = try HelperInstallScript.install(bundledHelper: "/Applications/iSensa.app/x", helperCDHash: hash, clientCDHash: hash)
        #expect(install.contains(legacy) && install.contains("/Library/PrivilegedHelperTools/app.sensa.Sensa.helper"))
        #expect(HelperInstallScript.uninstall().contains(legacy))
        #expect(FanHelper.label != FanHelper.legacyLabel)
    }

    @Test func quotesHostilePaths() throws {
        let script = try HelperInstallScript.install(bundledHelper: "/Users/a'b/$(rm -rf ~)/iSensa.app/h", helperCDHash: hash, clientCDHash: hash)
        #expect(script.contains("'/Users/a'\\''b/$(rm -rf ~)/iSensa.app/h'"))
    }

    @Test func rejectsMalformedHashes() {
        #expect(throws: FanControlFailure.self) {
            try HelperInstallScript.install(bundledHelper: "/x", helperCDHash: "zz\" ; rm -rf /", clientCDHash: hash)
        }
    }

    @Test func escapesForAppleScript() {
        let wrapped = HelperInstallScript.appleScript(running: #"echo "a\b""#, prompt: "iSensa")
        #expect(wrapped == #"do shell script "echo \"a\\b\"" with prompt "iSensa" with administrator privileges"#)
    }
}

@Suite("Temperature smoothing")
struct TemperatureSmootherTests {
    private let start = Date(timeIntervalSince1970: 5_000)

    @Test func firstReadingPassesThrough() {
        var smoother = TemperatureSmoother()
        #expect(smoother.update(60, at: start) == 60)
    }

    @Test func briefSpikeBarelyMovesTheValue() {
        var smoother = TemperatureSmoother()
        smoother.update(65, at: start)
        let spike = smoother.update(80, at: start.addingTimeInterval(2)) ?? .infinity
        let after = smoother.update(66, at: start.addingTimeInterval(4)) ?? .infinity
        #expect(spike < 69, "A 15 °C spike for one sample adds only a few degrees")
        #expect(after < 68, "and fades once the spike is gone")
    }

    @Test func sustainedRiseComesThroughWithinSeconds() {
        var smoother = TemperatureSmoother()
        smoother.update(60, at: start)
        var value = 60.0
        for second in stride(from: 2, through: 16, by: 2) {
            value = smoother.update(80, at: start.addingTimeInterval(TimeInterval(second))) ?? 0
        }
        #expect(value > 77, "After two time constants most of the rise is through")
    }

    @Test func repeatedOrOlderSamplesChangeNothing() {
        var smoother = TemperatureSmoother()
        smoother.update(60, at: start)
        smoother.update(70, at: start.addingTimeInterval(2))
        let value = smoother.value
        #expect(smoother.update(90, at: start.addingTimeInterval(2)) == value)
        #expect(smoother.update(90, at: start.addingTimeInterval(1)) == value)
    }

    @Test func longGapStartsOver() {
        var smoother = TemperatureSmoother()
        smoother.update(60, at: start)
        #expect(smoother.update(85, at: start.addingTimeInterval(60)) == 85)
    }

    @Test func ignoresInvalidReadings() {
        var smoother = TemperatureSmoother()
        #expect(smoother.update(.nan, at: start) == nil)
        smoother.update(60, at: start)
        #expect(smoother.update(.infinity, at: start.addingTimeInterval(2)) == 60)
    }
}

@Suite("Custom fan curves")
struct CustomCurveTests {
    private let base = FanCurve(points: [.init(50, 0.1), .init(65, 0.4), .init(80, 0.7), .init(90, 1)])

    @Test func pointsStayBetweenTheirNeighbours() {
        let moved = base.moving(pointAt: 1, celsius: 95, fraction: 0)
        #expect(moved.points[1].celsius == 77, "At most the gap below the next point")
        #expect(abs(moved.points[1].fraction - 0.1) < 1e-9, "Never slower than the previous point")
        let raised = base.moving(pointAt: 1, celsius: 40, fraction: 0.95)
        #expect(raised.points[1].celsius == 53)
        #expect(abs(raised.points[1].fraction - 0.7) < 1e-9, "Never faster than the next point")
    }

    @Test func lastPointIsAlwaysFullSpeedBelowTheCeiling() {
        let moved = base.moving(pointAt: 3, celsius: 120, fraction: 0.2)
        #expect(moved.points[3] == FanCurve.Point(98, 1))
        #expect(moved.fraction(at: 98) == 1)
    }

    @Test func movesSnapToSteps() {
        let moved = base.moving(pointAt: 2, celsius: 72.4, fraction: 0.53)
        #expect(moved.points[2].celsius == 72)
        #expect(abs(moved.points[2].fraction - 0.55) < 1e-9)
    }

    @Test func quietZoneFollowsTheFirstPoint() {
        let quiet = base.leavingFansToMacOSBelowFirstPoint(true)
        #expect(quiet.systemControlBelow == 50)
        #expect(quiet.moving(pointAt: 0, celsius: 58, fraction: 0).systemControlBelow == 58)
        #expect(quiet.leavingFansToMacOSBelowFirstPoint(false).systemControlBelow == nil)
    }

    @Test func enforcingSafetyRepairsAnyStoredCurve() {
        let broken = FanCurve(points: [.init(70, 0.8), .init(71, 0.9), .init(85, 0.2), .init(130, 0.5)], systemControlBelow: 95)
        let safe = broken.enforcingSafety()
        #expect(safe.points.map(\.celsius) == [70, 85, 98], "Too-close points dropped, temperatures clamped")
        #expect(safe.points.map(\.fraction) == [0.8, 0.8, 1], "Never slows down; ends at full speed")
        #expect(safe.systemControlBelow == 70)
        #expect(FanCurve(points: [.init(60, 0.5)]).enforcingSafety() == FanCurve.Preset.balanced.curve)
    }

    @Test func plannerUsesTheSafeVersionOfACustomCurve() {
        var planner = FanControlPlanner()
        let unsafe = FanCurve(points: [.init(40, 0.2), .init(60, 0.1)])
        let plan = planner.plan(mode: .custom(unsafe), temperature: 70, sampleAge: 1, thermalLevel: .nominal, limits: testLimits, now: Date())
        #expect(plan == .manual([FanTarget(index: 0, rpm: 6_800), FanTarget(index: 1, rpm: 6_800)]), "Past its last point: full speed")
    }

    @Test func customModeSurvivesARoundTrip() throws {
        let mode = FanMode.custom(base.leavingFansToMacOSBelowFirstPoint(true))
        let decoded = try JSONDecoder().decode(FanMode.self, from: JSONEncoder().encode(mode))
        #expect(decoded == mode)
        #expect(try JSONDecoder().decode(FanMode.self, from: Data(#"{"curve":{"_0":"performance"}}"#.utf8)) == .curve(.performance))
    }
}
