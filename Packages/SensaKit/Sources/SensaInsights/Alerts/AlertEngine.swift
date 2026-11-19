import Foundation
import SensaCore

/// Kinds of alert. Raw values are stored in history, so they must never change.
public enum AlertKind: String, Sendable, CaseIterable, Codable {
    case highTemperature, memoryPressure, lowStorage, lowBattery, batteryCharged, batteryTemperature, ssdHealth, sensorUnavailable
    case storageFillingFast
}

/// An alert that just started.
public struct AlertEvent: Sendable, Equatable {
    public let kind: AlertKind
    public let level: HealthLevel
    /// Triggering value in the rule's canonical unit (°C or fraction), when meaningful.
    public let value: Double?
    public let date: Date

    public init(kind: AlertKind, level: HealthLevel, value: Double?, date: Date) {
        self.kind = kind
        self.level = level
        self.value = value
        self.date = date
    }
}

/// Turns snapshots into alert events. Each rule must hold for a minimum duration before it fires,
/// needs to recover past a hysteresis margin before it can fire again, and never repeats within
/// the configured interval. Pure state machine: no clocks, no notifications.
public struct AlertEngine: Sendable {
    private struct RuleState: Sendable {
        var conditionSince: Date?
        var isActive = false
        var lastFired: Date?
    }

    /// Margins a value must recover by before an active alert clears.
    static let temperatureHysteresis = 5.0
    static let fractionHysteresis = 0.03

    private var states: [AlertKind: RuleState] = [:]
    /// Recent free space of the startup disk, oldest first, for `storageFillingFast`.
    private var recentFreeSpace: [(date: Date, available: UInt64)] = []

    public init() {}

    public mutating func evaluate(
        _ snapshot: SystemSnapshot, capabilities: CapabilityMap, configuration: AlertConfiguration, now: Date
    ) -> [AlertEvent] {
        guard configuration.isEnabled else {
            states.removeAll()
            recentFreeSpace.removeAll()
            return []
        }
        rememberFreeSpace(snapshot, now: now)
        return AlertKind.allCases.compactMap { kind in
            let check = condition(kind, snapshot: snapshot, capabilities: capabilities, configuration: configuration)
            return step(kind, check: check, configuration: configuration, now: now)
        }
    }

    /// What a rule sees right now.
    private struct Check {
        /// The alert condition holds.
        var triggered: Bool
        /// The condition has recovered past hysteresis (an active alert may clear).
        var recovered: Bool
        var level: HealthLevel = .attention
        var value: Double?
        /// Wait for `sustainedSeconds` before firing (noisy signals like temperature).
        var needsSustain = false
    }

    private mutating func step(_ kind: AlertKind, check: Check?, configuration: AlertConfiguration, now: Date) -> AlertEvent? {
        var state = states[kind, default: RuleState()]
        defer { states[kind] = state }
        guard let check else {
            state.conditionSince = nil
            return nil
        }
        if state.isActive {
            if check.recovered {
                state.isActive = false
                state.conditionSince = nil
            }
            return nil
        }
        guard check.triggered else {
            state.conditionSince = nil
            return nil
        }
        let since = state.conditionSince ?? now
        state.conditionSince = since
        if check.needsSustain, now.timeIntervalSince(since) < configuration.sustainedSeconds { return nil }
        if let last = state.lastFired, now.timeIntervalSince(last) < configuration.repeatInterval { return nil }
        state.isActive = true
        state.lastFired = now
        return AlertEvent(kind: kind, level: check.level, value: check.value, date: now)
    }

    private mutating func rememberFreeSpace(_ snapshot: SystemSnapshot, now: Date) {
        recentFreeSpace.removeAll { now.timeIntervalSince($0.date) > AlertConfiguration.storageGrowthWindow }
        guard let root = snapshot.storage?.rootVolume else { return }
        if recentFreeSpace.last?.available != root.availableCapacity || recentFreeSpace.isEmpty {
            recentFreeSpace.append((now, root.availableCapacity))
        }
    }

    /// Free space lost within the window: from the most free seen in it down to now.
    private var freeSpaceLost: Double? {
        guard let current = recentFreeSpace.last?.available, let most = recentFreeSpace.map(\.available).max() else { return nil }
        return Double(most) - Double(current)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func condition(
        _ kind: AlertKind, snapshot: SystemSnapshot, capabilities: CapabilityMap, configuration: AlertConfiguration
    ) -> Check? {
        switch kind {
        case .highTemperature:
            let rule = configuration.highTemperature
            guard rule.isEnabled, let temperature = snapshot.sensors?.cpuTemperature else { return nil }
            return Check(
                triggered: temperature >= rule.threshold, recovered: temperature < rule.threshold - Self.temperatureHysteresis,
                level: snapshot.thermal?.level == .critical ? .critical : .attention, value: temperature, needsSustain: true
            )
        case .memoryPressure:
            guard configuration.memoryPressure.isEnabled, let memory = snapshot.memory else { return nil }
            return Check(
                triggered: memory.pressure != .normal, recovered: memory.pressure == .normal,
                level: memory.pressure == .critical ? .critical : .attention, value: memory.pressureFraction, needsSustain: true
            )
        case .lowStorage:
            let rule = configuration.lowStorage
            guard rule.isEnabled, let root = snapshot.storage?.rootVolume, root.totalCapacity > 0 else { return nil }
            let free = 1 - root.usedFraction
            return Check(
                triggered: free <= rule.threshold, recovered: free > rule.threshold + Self.fractionHysteresis,
                level: free <= rule.threshold / 3 ? .critical : .attention, value: free
            )
        case .lowBattery:
            let rule = configuration.lowBattery
            guard rule.isEnabled, let battery = snapshot.battery else { return nil }
            let discharging = battery.state == .discharging
            return Check(
                triggered: discharging && battery.charge <= rule.threshold,
                recovered: !discharging || battery.charge > rule.threshold + Self.fractionHysteresis,
                level: battery.charge <= 0.05 ? .critical : .attention, value: battery.charge
            )
        case .batteryCharged:
            let rule = configuration.batteryCharged
            guard rule.isEnabled, let battery = snapshot.battery else { return nil }
            let onPower = battery.state != .discharging
            return Check(
                triggered: onPower && battery.charge >= rule.threshold,
                recovered: !onPower || battery.charge < rule.threshold - Self.fractionHysteresis,
                level: .normal, value: battery.charge
            )
        case .batteryTemperature:
            let rule = configuration.batteryTemperature
            guard rule.isEnabled, let temperature = snapshot.battery?.temperature else { return nil }
            return Check(
                triggered: temperature >= rule.threshold, recovered: temperature < rule.threshold - Self.temperatureHysteresis / 2,
                value: temperature, needsSustain: true
            )
        case .storageFillingFast:
            let rule = configuration.storageFillingFast
            guard rule.isEnabled, let lost = freeSpaceLost else { return nil }
            return Check(triggered: lost >= rule.threshold, recovered: lost < rule.threshold / 2, value: lost)
        case .ssdHealth:
            guard configuration.ssdHealth.isEnabled, let health = snapshot.storage?.ssdHealth else { return nil }
            return Check(triggered: health.reportsCriticalCondition, recovered: !health.reportsCriticalCondition, level: .critical)
        case .sensorUnavailable:
            guard configuration.sensorUnavailable.isEnabled, let state = capabilities[.temperatureSensors] else { return nil }
            let unavailable = state == .temporarilyUnavailable
            return Check(triggered: unavailable, recovered: !unavailable, needsSustain: true)
        }
    }
}
