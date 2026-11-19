import Foundation
import iSensaCore

/// Collects data from providers on per-tier schedules, isolated from rendering.
///
/// - Each tier runs in its own task; providers within a cycle are sampled concurrently.
/// - A failing provider is marked `temporarilyUnavailable` and retried with backoff.
/// - Demand / power changes restart the loops so new intervals apply immediately.
/// - `suspend()` (system sleep) cancels every loop; `resume()` re-probes and restarts.
public actor MonitoringEngine {
    public nonisolated let events: AsyncStream<EngineEvent>
    private let continuation: AsyncStream<EngineEvent>.Continuation

    private let providers: [any MetricProvider]
    private var policy: SamplingPolicy
    private var demand: Demand = .interactive
    private var onBattery = false
    private var health: [String: ProviderHealth] = [:]
    private var usable: Set<String> = []
    private var loops: [Task<Void, Never>] = []
    private var isRunning = false

    public init(providers: [any MetricProvider], policy: SamplingPolicy = SamplingPolicy()) {
        self.providers = providers
        self.policy = policy
        (events, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(256))
    }

    deinit {
        loops.forEach { $0.cancel() }
        continuation.finish()
    }

    // MARK: - Lifecycle

    public func start() async {
        guard !isRunning else { return }
        isRunning = true
        await probeAll()
        await prepareProviders()
        startLoops()
    }

    public func suspend() {
        isRunning = false
        stopLoops()
    }

    public func resume() async {
        await start()
    }

    public func setDemand(_ demand: Demand) async {
        guard demand != self.demand else { return }
        let increased = demand > self.demand
        self.demand = demand
        await prepareProviders()
        restartLoops(sampleImmediately: increased)
    }

    private func prepareProviders() async {
        let demand = demand
        await withTaskGroup(of: Void.self) { group in
            for provider in providers {
                group.addTask { await provider.prepare(for: demand) }
            }
        }
    }

    public func setOnBattery(_ onBattery: Bool) {
        guard onBattery != self.onBattery else { return }
        self.onBattery = onBattery
        restartLoops(sampleImmediately: false)
    }

    public func setPolicy(_ policy: SamplingPolicy) {
        guard policy != self.policy else { return }
        self.policy = policy
        restartLoops(sampleImmediately: false)
    }

    public func currentInterval(for tier: SamplingTier) -> Duration {
        policy.interval(for: tier, demand: demand, onBattery: onBattery)
    }

    // MARK: - Sampling

    /// Probes every provider and publishes the resulting capability states.
    func probeAll() async {
        let results = await withTaskGroup(of: (String, Feature, CapabilityState).self) { group in
            for provider in providers {
                group.addTask { (provider.id, provider.feature, await provider.probe()) }
            }
            var collected: [(String, Feature, CapabilityState)] = []
            for await result in group { collected.append(result) }
            return collected
        }
        usable = Set(results.filter { $0.2.isUsable }.map(\.0))
        for (_, feature, state) in results {
            continuation.yield(.capability(feature, state))
        }
    }

    /// Samples every usable provider of a tier once. Internal for tests.
    func sampleOnce(tier: SamplingTier) async {
        var due: [any MetricProvider] = []
        for provider in providers where provider.tier == tier && usable.contains(provider.id) && provider.minimumDemand <= demand {
            var state = health[provider.id, default: ProviderHealth()]
            if state.shouldSample() { due.append(provider) }
            health[provider.id] = state
        }
        guard !due.isEmpty else { return }
        let outcomes = await withTaskGroup(of: (any MetricProvider, Result<any SnapshotFragment, any Error>).self) { group in
            for provider in due {
                group.addTask {
                    do { return (provider, .success(try await provider.sample())) } catch { return (provider, .failure(error)) }
                }
            }
            var collected: [(any MetricProvider, Result<any SnapshotFragment, any Error>)] = []
            for await result in group { collected.append(result) }
            return collected
        }
        for (provider, outcome) in outcomes {
            handle(outcome, from: provider)
        }
    }

    private func handle(_ outcome: Result<any SnapshotFragment, any Error>, from provider: any MetricProvider) {
        var state = health[provider.id, default: ProviderHealth()]
        switch outcome {
        case let .success(fragment):
            if state.recordSuccess() {
                continuation.yield(.capability(provider.feature, .available))
                Task { await self.republishProbe(of: provider) }
            }
            continuation.yield(.fragment(fragment))
        case .failure:
            if state.recordFailure() {
                continuation.yield(.capability(provider.feature, .temporarilyUnavailable))
            }
        }
        health[provider.id] = state
    }

    /// After recovery, restore the provider's precise state (e.g. `.experimental`).
    private func republishProbe(of provider: any MetricProvider) async {
        continuation.yield(.capability(provider.feature, await provider.probe()))
    }

    // MARK: - Loops

    private func startLoops(sampleImmediately: Bool = true) {
        stopLoops()
        loops = SamplingTier.allCases.map { tier in
            Task { [weak self] in
                guard let self else { return }
                if sampleImmediately { await self.sampleOnce(tier: tier) }
                while !Task.isCancelled {
                    let interval = await self.currentInterval(for: tier)
                    // Tolerance lets the system coalesce wake-ups (energy efficiency).
                    try? await Task.sleep(for: interval, tolerance: interval / 10)
                    guard !Task.isCancelled else { return }
                    await self.sampleOnce(tier: tier)
                }
            }
        }
    }

    private func stopLoops() {
        loops.forEach { $0.cancel() }
        loops = []
    }

    private func restartLoops(sampleImmediately: Bool) {
        guard isRunning else { return }
        startLoops(sampleImmediately: sampleImmediately)
    }
}
