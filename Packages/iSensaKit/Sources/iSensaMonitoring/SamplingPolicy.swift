import Foundation
import iSensaCore

/// Maps tier × demand × power source to a sampling interval. Pure and testable.
public struct SamplingPolicy: Sendable, Equatable {
    /// Base interval of the fast tier while interactive (user preference, seconds).
    public var interactiveInterval: Double
    /// Base interval of the fast tier when only the menu bar is visible.
    public var backgroundInterval: Double
    /// Multiplier applied on battery power to save energy.
    public var batteryMultiplier: Double

    public init(interactiveInterval: Double = 1, backgroundInterval: Double = 3, batteryMultiplier: Double = 1.5) {
        self.interactiveInterval = interactiveInterval
        self.backgroundInterval = backgroundInterval
        self.batteryMultiplier = batteryMultiplier
    }

    public func interval(for tier: SamplingTier, demand: Demand, onBattery: Bool) -> Duration {
        let base: Double = switch demand {
        case .interactive: interactiveInterval
        case .background: backgroundInterval
        case .idle: 30
        }
        let tierFactor: Double = switch tier {
        case .fast: 1
        case .medium: 2
        case .slow: 10
        }
        let seconds = base * tierFactor * (onBattery ? batteryMultiplier : 1)
        return .milliseconds(Int((seconds * 1_000).rounded()))
    }
}
