import Foundation
@testable import SensaControl
import SensaCore
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
            #expect(preset.curve.fraction(at: 95) == 1, "\(preset)")
        }
    }
}

@Suite("Fan control planner")
struct PlannerTests {
    private func plan(
        _ planner: inout FanControlPlanner, _ mode: FanMode, _ temperature: Double?, age: TimeInterval = 1, thermal: ThermalLevel? = .nominal
    ) -> FanPlan {
        planner.plan(mode: mode, cpuTemperature: temperature, sampleAge: age, thermalLevel: thermal, limits: testLimits)
    }

    @Test func automaticAndSafetyConditionsHandControlToMacOS() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .automatic, 70) == .system(.userChoice))
        #expect(plan(&planner, .curve(.performance), nil) == .system(.noTemperature))
        #expect(plan(&planner, .curve(.performance), 70, age: 60) == .system(.noTemperature), "Stale readings count as missing")
        #expect(plan(&planner, .fixed(fraction: 1), 70, thermal: .serious) == .system(.thermalPressure))
        #expect(plan(&planner, .fixed(fraction: 0.2), 92) == .system(.tooHotForFixedSpeed))
        #expect(planner.plan(mode: .fixed(fraction: 1), cpuTemperature: 70, sampleAge: 1, thermalLevel: .nominal, limits: []) == .system(.noLimits))
    }

    @Test func fixedSpeedTargetsEveryFan() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .fixed(fraction: 1), 92) == .manual([FanTarget(index: 0, rpm: 6_800), FanTarget(index: 1, rpm: 6_800)]))
    }

    @Test func curveQuietZoneUsesHysteresis() {
        var planner = FanControlPlanner()
        #expect(plan(&planner, .curve(.balanced), 50) == .system(.coolEnough))
        #expect(plan(&planner, .curve(.balanced), 54) == .system(.coolEnough))
        guard case .manual = plan(&planner, .curve(.balanced), 56) else { Issue.record("Should take control above 55 °C"); return }
        guard case .manual = plan(&planner, .curve(.balanced), 53) else { Issue.record("Should keep control inside the hysteresis band"); return }
        #expect(plan(&planner, .curve(.balanced), 51) == .system(.coolEnough))
    }

    @Test func curveSpeedsMoveInTenPercentStepsRoundedUp() {
        #expect(FanControlPlanner.stepped(0) == 0)
        #expect(abs(FanControlPlanner.stepped(0.31) - 0.4) < 1e-9)
        #expect(abs(FanControlPlanner.stepped(0.3) - 0.3) < 1e-9)
        #expect(FanControlPlanner.stepped(0.99) == 1)
    }

    @Test func speedsUpAtOnceButSlowsDownGradually() throws {
        var planner = FanControlPlanner()
        let hot = plan(&planner, .curve(.performance), 85)
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
        let script = try HelperInstallScript.install(bundledHelper: "/Applications/Sensa.app/x", helperCDHash: hash, clientCDHash: hash)
        let copy = try #require(script.range(of: "/bin/cp "))
        let verify = try #require(script.range(of: "codesign --verify -R '=cdhash H\"\(hash)\"'"))
        let bootstrap = try #require(script.range(of: "launchctl bootstrap system"))
        #expect(copy.lowerBound < verify.lowerBound && verify.lowerBound < bootstrap.lowerBound)
        #expect(script.contains("<string>--client-cdhash</string>"))
        #expect(script.contains("<key>RunAtLoad</key><true/>"))
    }

    @Test func quotesHostilePaths() throws {
        let script = try HelperInstallScript.install(bundledHelper: "/Users/a'b/$(rm -rf ~)/Sensa.app/h", helperCDHash: hash, clientCDHash: hash)
        #expect(script.contains("'/Users/a'\\''b/$(rm -rf ~)/Sensa.app/h'"))
    }

    @Test func rejectsMalformedHashes() {
        #expect(throws: FanControlFailure.self) {
            try HelperInstallScript.install(bundledHelper: "/x", helperCDHash: "zz\" ; rm -rf /", clientCDHash: hash)
        }
    }

    @Test func escapesForAppleScript() {
        let wrapped = HelperInstallScript.appleScript(running: #"echo "a\b""#, prompt: "Sensa")
        #expect(wrapped == #"do shell script "echo \"a\\b\"" with prompt "Sensa" with administrator privileges"#)
    }
}
