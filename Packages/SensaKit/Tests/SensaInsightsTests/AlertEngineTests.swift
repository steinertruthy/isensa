import Foundation
import SensaCore
@testable import SensaInsights
import Testing

@Suite("Alert engine")
struct AlertEngineTests {
    private let start = Date(timeIntervalSince1970: 0)

    private func configuration() -> AlertConfiguration {
        var configuration = AlertConfiguration()
        configuration.isEnabled = true
        configuration.sustainedSeconds = 60
        configuration.repeatInterval = 600
        return configuration
    }

    private func snapshot(temperature: Double) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        snapshot.sensors = SensorSnapshot(timestamp: start, sensors: [], fans: [], cpuTemperature: temperature, gpuTemperature: nil, systemPower: nil)
        return snapshot
    }

    private func battery(_ charge: Double, _ state: ChargeState) -> SystemSnapshot {
        var snapshot = SystemSnapshot()
        snapshot.battery = BatterySnapshot(
            timestamp: start, charge: charge, state: state, isExternalPowerConnected: state != .discharging, cycleCount: nil,
            designCapacity: nil, nominalCapacity: nil, rawMaxCapacity: nil, remainingCapacity: nil, voltage: nil,
            amperage: nil, temperature: nil, timeToEmpty: nil, timeToFull: nil, systemCondition: nil, adapter: nil
        )
        return snapshot
    }

    private func run(_ engine: inout AlertEngine, _ snapshot: SystemSnapshot, at seconds: TimeInterval, _ config: AlertConfiguration? = nil) -> [AlertKind] {
        engine.evaluate(snapshot, capabilities: CapabilityMap(), configuration: config ?? configuration(), now: start.addingTimeInterval(seconds)).map(\.kind)
    }

    @Test func notificationsOffNeverFire() {
        var engine = AlertEngine()
        var off = configuration()
        off.isEnabled = false
        #expect(run(&engine, snapshot(temperature: 120), at: 0, off).isEmpty)
        #expect(run(&engine, snapshot(temperature: 120), at: 600, off).isEmpty)
    }

    @Test func temperatureMustBeSustained() {
        var engine = AlertEngine()
        #expect(run(&engine, snapshot(temperature: 99), at: 0).isEmpty)
        #expect(run(&engine, snapshot(temperature: 99), at: 30).isEmpty)
        #expect(run(&engine, snapshot(temperature: 99), at: 61) == [.highTemperature])
        #expect(run(&engine, snapshot(temperature: 99), at: 120).isEmpty, "Fires once while active")
    }

    @Test func briefSpikeDoesNotFire() {
        var engine = AlertEngine()
        _ = run(&engine, snapshot(temperature: 99), at: 0)
        _ = run(&engine, snapshot(temperature: 80), at: 30)
        #expect(run(&engine, snapshot(temperature: 99), at: 70).isEmpty, "Duration restarts after the spike")
    }

    @Test func hysteresisAndRepeatInterval() {
        var engine = AlertEngine()
        _ = run(&engine, snapshot(temperature: 99), at: 0)
        #expect(run(&engine, snapshot(temperature: 99), at: 61) == [.highTemperature])
        _ = run(&engine, snapshot(temperature: 93), at: 100) // below threshold but within hysteresis: stays active
        #expect(run(&engine, snapshot(temperature: 99), at: 200).isEmpty)
        _ = run(&engine, snapshot(temperature: 85), at: 300) // recovered
        _ = run(&engine, snapshot(temperature: 99), at: 310)
        #expect(run(&engine, snapshot(temperature: 99), at: 400).isEmpty, "Within the repeat interval")
        #expect(run(&engine, snapshot(temperature: 99), at: 670) == [.highTemperature], "Fires again once the repeat interval has passed")
    }

    @Test func lowBatteryOnlyWhileDischarging() {
        var engine = AlertEngine()
        #expect(run(&engine, battery(0.15, .charging), at: 0).isEmpty)
        #expect(run(&engine, battery(0.15, .discharging), at: 1) == [.lowBattery])
        _ = run(&engine, battery(0.16, .charging), at: 2)
        #expect(run(&engine, battery(0.15, .discharging), at: 3).isEmpty, "Repeat interval still applies")
    }

    @Test func batteryChargedIsOptInAndInformational() throws {
        var engine = AlertEngine()
        #expect(run(&engine, battery(0.85, .charging), at: 0).isEmpty)
        var config = configuration()
        config.batteryCharged.isEnabled = true
        let events = engine.evaluate(battery(0.85, .charging), capabilities: CapabilityMap(), configuration: config, now: start)
        let event = try #require(events.first)
        #expect(event.kind == .batteryCharged)
        #expect(event.level == .normal)
    }

    @Test func sensorOutageUsesCapabilities() {
        var engine = AlertEngine()
        var config = configuration()
        config.sensorUnavailable.isEnabled = true
        let capabilities = CapabilityMap([.temperatureSensors: .temporarilyUnavailable])
        #expect(engine.evaluate(SystemSnapshot(), capabilities: capabilities, configuration: config, now: start).isEmpty)
        let events = engine.evaluate(SystemSnapshot(), capabilities: capabilities, configuration: config, now: start.addingTimeInterval(61))
        #expect(events.map(\.kind) == [.sensorUnavailable])
    }
}
