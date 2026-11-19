import Foundation
import SensaCore

/// Why control is (or went back) with macOS.
public enum SystemControlReason: String, Codable, Sendable {
    /// The user chose automatic.
    case userChoice
    /// A curve's quiet zone: cool enough for macOS to manage (fans may stop).
    case coolEnough
    /// No recent temperature reading: never steer fans blind.
    case noTemperature
    /// macOS reports serious or critical thermal pressure.
    case thermalPressure
    /// A fixed speed below maximum while the hottest CPU core is very hot.
    case tooHotForFixedSpeed
    /// Fan limits could not be read or are implausible.
    case noLimits
}

public enum FanPlan: Equatable, Sendable {
    case system(SystemControlReason)
    case manual([FanTarget])
}

/// Pure decision logic for the app side: turns the user's mode and the latest readings into either
/// "let macOS decide" or validated targets. Smooths curves with hysteresis so fans don't hunt.
///
/// `temperature` is the control temperature: the hottest CPU core, already smoothed over time by
/// `TemperatureSmoother`.
public struct FanControlPlanner: Sendable {
    /// Readings older than this are treated as missing.
    public static let maximumSampleAge: TimeInterval = 15
    /// A fixed speed below maximum is abandoned above this temperature, and resumed only once the
    /// temperature has dropped `hysteresis` below it.
    public static let fixedSpeedCeiling: Double = 90
    /// Degrees the temperature must fall before a curve slows the fans down again.
    public static let hysteresis: Double = 3
    /// Largest drop in range fraction per update, so slowing down is gradual.
    public static let maximumStepDown: Double = 0.1
    /// Curve speeds move in steps of this fraction of the range (rounded up, never below the curve),
    /// so small temperature changes don't turn into a stream of hardware writes.
    public static let curveStep: Double = 0.1

    private var lastFraction: Double?
    private var inQuietZone = false
    private var tooHotForFixed = false

    public init() {}

    public mutating func plan(
        mode: FanMode, temperature reading: Double?, sampleAge: TimeInterval, thermalLevel: ThermalLevel?, limits: [FanLimits]
    ) -> FanPlan {
        guard mode.isManual else { return reset(.userChoice) }
        if let thermalLevel, thermalLevel >= .serious { return reset(.thermalPressure) }
        let valid = limits.filter(\.isValid)
        guard !valid.isEmpty else { return reset(.noLimits) }
        let temperature = sampleAge <= Self.maximumSampleAge ? reading.flatMap { $0.isFinite ? $0 : nil } : nil

        let fraction: Double
        switch mode {
        case .automatic:
            return reset(.userChoice)
        case let .fixed(requested):
            if requested < 1, let temperature {
                let limit = tooHotForFixed ? Self.fixedSpeedCeiling - Self.hysteresis : Self.fixedSpeedCeiling
                tooHotForFixed = temperature >= limit
                if tooHotForFixed { return reset(.tooHotForFixedSpeed) }
            }
            fraction = min(max(requested, 0), 1)
        case .curve, .custom:
            guard let temperature, let curve = mode.curve else { return reset(.noTemperature) }
            if let quietBelow = curve.systemControlBelow {
                // Leave the quiet zone at its edge; return to it only well below (hysteresis).
                inQuietZone = inQuietZone ? temperature < quietBelow : temperature < quietBelow - Self.hysteresis
                if inQuietZone { return reset(.coolEnough) }
            }
            let rising = Self.stepped(curve.fraction(at: temperature))
            let falling = Self.stepped(curve.fraction(at: temperature + Self.hysteresis))
            fraction = smoothed(rising: rising, falling: falling)
        }
        lastFraction = fraction
        return .manual(valid.map { FanTarget(index: $0.index, rpm: $0.rpm(atFraction: fraction)) })
    }

    static func stepped(_ fraction: Double) -> Double {
        min((fraction / curveStep - 1e-9).rounded(.up) * curveStep, 1)
    }

    /// Speeds up immediately; slows down only past the hysteresis band, and gradually.
    private func smoothed(rising: Double, falling: Double) -> Double {
        guard let lastFraction else { return rising }
        if rising >= lastFraction { return rising }
        let target = min(falling, lastFraction)
        return max(target, lastFraction - Self.maximumStepDown)
    }

    private mutating func reset(_ reason: SystemControlReason) -> FanPlan {
        lastFraction = nil
        if reason != .coolEnough { inQuietZone = false }
        if reason != .tooHotForFixedSpeed { tooHotForFixed = false }
        return .system(reason)
    }
}
