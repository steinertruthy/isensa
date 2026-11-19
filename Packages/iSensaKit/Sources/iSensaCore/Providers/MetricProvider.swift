import Foundation

/// How often a provider's data meaningfully changes. The engine maps tiers to
/// concrete intervals depending on demand (window visible, menu bar only...) and power source.
public enum SamplingTier: Int, Sendable, CaseIterable, Comparable, Hashable {
    /// CPU, GPU, network — changes every second.
    case fast
    /// Temperatures, fans, power — thermal inertia makes 2–3 s sufficient.
    case medium
    /// Battery, storage capacity — changes over tens of seconds.
    case slow

    public static func < (lhs: SamplingTier, rhs: SamplingTier) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Contract every data source implements. Implementations are usually actors because
/// they keep previous counters to compute rates.
public protocol MetricProvider: Sendable {
    /// Stable identifier, used for logs and diagnostics.
    var id: String { get }
    /// Feature this provider backs; its probe result becomes that feature's capability state.
    var feature: Feature { get }
    var tier: SamplingTier { get }

    /// Discovers whether this Mac supports the provider. Must be cheap and side-effect free.
    func probe() async -> CapabilityState

    /// Takes one sample. Throwing marks the feature temporarily unavailable; the engine retries with backoff.
    func sample() async throws -> any SnapshotFragment

    /// Lowest demand at which sampling this provider is worthwhile. Data only shown in the
    /// main window or popover (processes, clock speeds…) is skipped while nobody looks at it.
    var minimumDemand: Demand { get }

    /// Called when demand changes, so a provider can trade detail for energy (e.g. read only
    /// headline sensors while just the menu bar is visible).
    func prepare(for demand: Demand) async
}

public extension MetricProvider {
    var minimumDemand: Demand { .idle }
    func prepare(for demand: Demand) async {}
}

public enum ProviderError: Error, Sendable, Equatable {
    case interfaceUnavailable(String)
    case readFailed(String)
}
