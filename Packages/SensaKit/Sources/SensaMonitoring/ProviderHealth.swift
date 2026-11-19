import Foundation

/// Failure bookkeeping for one provider: exponential backoff in whole cycles,
/// so a broken sensor never slows down or crashes the rest of the engine.
struct ProviderHealth: Sendable, Equatable {
    private(set) var consecutiveFailures = 0
    private(set) var cyclesToSkip = 0
    static let maximumBackoffCycles = 32

    /// Returns `true` if the provider should be sampled this cycle.
    mutating func shouldSample() -> Bool {
        guard cyclesToSkip == 0 else {
            cyclesToSkip -= 1
            return false
        }
        return true
    }

    /// Returns `true` when this failure is a transition from healthy to failing.
    mutating func recordFailure() -> Bool {
        consecutiveFailures += 1
        cyclesToSkip = min(1 << min(consecutiveFailures - 1, 5), Self.maximumBackoffCycles)
        return consecutiveFailures == 1
    }

    /// Returns `true` when this success recovers from a failing state.
    mutating func recordSuccess() -> Bool {
        defer {
            consecutiveFailures = 0
            cyclesToSkip = 0
        }
        return consecutiveFailures > 0
    }
}
