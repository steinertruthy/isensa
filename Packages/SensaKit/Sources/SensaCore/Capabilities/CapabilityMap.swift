import Foundation

/// Snapshot of every feature's availability. Missing entries mean "not probed yet".
public struct CapabilityMap: Sendable, Hashable {
    private var states: [Feature: CapabilityState]

    public init(_ states: [Feature: CapabilityState] = [:]) {
        self.states = states
    }

    public subscript(feature: Feature) -> CapabilityState? {
        get { states[feature] }
        set { states[feature] = newValue }
    }

    public func isUsable(_ feature: Feature) -> Bool {
        states[feature]?.isUsable ?? false
    }

    /// Features are shown when present on the hardware, or while still being discovered.
    public func isPresent(_ feature: Feature) -> Bool {
        states[feature]?.isPresent ?? true
    }

    public var probedFeatures: [Feature] {
        Feature.allCases.filter { states[$0] != nil }
    }
}
