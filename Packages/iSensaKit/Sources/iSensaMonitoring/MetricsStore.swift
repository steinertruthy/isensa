import Foundation
import Observation
import iSensaCore

/// Main-actor state the UI observes: latest snapshot, capabilities and live series.
/// Fed exclusively by the engine's event stream (collection and rendering are decoupled).
@MainActor
@Observable
public final class MetricsStore {
    public private(set) var snapshot = SystemSnapshot()
    public private(set) var capabilities: CapabilityMap
    public let profile: HardwareProfile
    /// `true` when the data comes from demonstration providers.
    public let isDemo: Bool

    @ObservationIgnored private var series: [MetricID: MetricSeries] = [:]
    @ObservationIgnored private let seriesCapacity: Int
    @ObservationIgnored private var consumer: Task<Void, Never>?
    @ObservationIgnored private var readingObservers: [@MainActor ([Reading]) -> Void] = []

    public init(profile: HardwareProfile, staticCapabilities: [Feature: CapabilityState] = [:], isDemo: Bool = false, seriesCapacity: Int = 120) {
        self.profile = profile
        self.capabilities = CapabilityMap(staticCapabilities)
        self.isDemo = isDemo
        self.seriesCapacity = seriesCapacity
    }

    /// Starts consuming engine events. Cancelling the returned task (or `stop()`) ends it.
    public func consume(_ events: AsyncStream<EngineEvent>) {
        consumer?.cancel()
        consumer = Task { [weak self] in
            for await event in events {
                self?.handle(event)
            }
        }
    }

    /// Called after each fragment is applied, with its (demo-tagged) readings — used by history
    /// recording and alert evaluation, which must see every sample, not just what views render.
    public func addReadingObserver(_ observer: @escaping @MainActor ([Reading]) -> Void) {
        readingObservers.append(observer)
    }

    public func stop() {
        consumer?.cancel()
        consumer = nil
    }

    public func handle(_ event: EngineEvent) {
        switch event {
        case let .fragment(fragment):
            fragment.apply(to: &snapshot)
            var published: [Reading] = []
            for reading in fragment.readings {
                // Demo and production providers never mix, so in demo mode every value is tagged as demo.
                let tagged = isDemo
                    ? Reading(metric: reading.metric, value: reading.value, unit: reading.unit, timestamp: reading.timestamp, provenance: .demo)
                    : reading
                series(for: tagged.metric, unit: tagged.unit).append(tagged)
                published.append(tagged)
            }
            readingObservers.forEach { $0(published) }
        case let .capability(feature, state):
            if capabilities[feature] != state { capabilities[feature] = state }
        }
    }

    /// Stable series object for a metric (created on first access).
    public func series(for metric: MetricID, unit: MetricUnit = .fraction) -> MetricSeries {
        if let existing = series[metric] { return existing }
        let created = MetricSeries(id: metric, unit: unit, capacity: seriesCapacity)
        series[metric] = created
        return created
    }
}
