import Foundation
@testable import iSensaMonitoring
import iSensaCore
import Testing

private struct StubFragment: SnapshotFragment {
    let value: Double
    func apply(to snapshot: inout SystemSnapshot) {
        snapshot.thermal = ThermalSnapshot(timestamp: Date(), level: .fair, pressure: nil)
    }
    var readings: [Reading] {
        [Reading(metric: .cpuUsage, value: value, unit: .fraction, timestamp: Date(), provenance: .system(api: "stub"))]
    }
}

private actor StubProvider: MetricProvider {
    nonisolated let id: String
    nonisolated let feature: Feature
    nonisolated let tier: SamplingTier
    private let probeResult: CapabilityState
    private var failuresRemaining: Int
    private(set) var sampleCount = 0

    nonisolated let minimumDemand: Demand
    private(set) var preparedDemands: [Demand] = []

    init(
        id: String, feature: Feature = .cpuUsage, tier: SamplingTier = .fast, probe: CapabilityState = .available,
        failures: Int = 0, minimumDemand: Demand = .idle
    ) {
        self.minimumDemand = minimumDemand
        self.id = id
        self.feature = feature
        self.tier = tier
        self.probeResult = probe
        self.failuresRemaining = failures
    }

    func probe() async -> CapabilityState { probeResult }

    func prepare(for demand: Demand) async { preparedDemands.append(demand) }

    func sample() async throws -> any SnapshotFragment {
        sampleCount += 1
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw ProviderError.readFailed("stub")
        }
        return StubFragment(value: Double(sampleCount))
    }
}

private actor EventCollector {
    var events: [EngineEvent] = []
    func append(_ event: EngineEvent) { events.append(event) }
}

@Suite("Monitoring engine")
struct EngineTests {
    @Test func samplingPolicyScalesWithTierDemandAndPower() {
        let policy = SamplingPolicy(interactiveInterval: 1, backgroundInterval: 3, batteryMultiplier: 2)
        #expect(policy.interval(for: .fast, demand: .interactive, onBattery: false) == .seconds(1))
        #expect(policy.interval(for: .medium, demand: .interactive, onBattery: false) == .seconds(2))
        #expect(policy.interval(for: .slow, demand: .background, onBattery: false) == .seconds(30))
        #expect(policy.interval(for: .fast, demand: .background, onBattery: true) == .seconds(6))
    }

    @Test func backoffGrowsAndResets() {
        var health = ProviderHealth()
        var schedule: [Bool] = []
        func step() { schedule.append(health.shouldSample()) }

        let firstFailureIsTransition = health.recordFailure()
        step(); step()
        let secondFailureIsTransition = health.recordFailure()
        step(); step(); step()
        let recovered = health.recordSuccess()
        step()

        #expect(firstFailureIsTransition)
        #expect(!secondFailureIsTransition)
        #expect(recovered)
        #expect(schedule == [false, true, false, false, true, true])
    }

    @Test func unsupportedProvidersAreNeverSampled() async {
        let unsupported = StubProvider(id: "u", probe: .unsupported)
        let engine = MonitoringEngine(providers: [unsupported])
        await engine.probeAll()
        await engine.sampleOnce(tier: .fast)
        #expect(await unsupported.sampleCount == 0)
    }

    @Test func failingProviderDoesNotBlockOthersAndRecovers() async {
        let healthy = StubProvider(id: "healthy")
        let flaky = StubProvider(id: "flaky", feature: .gpuUsage, failures: 1)
        let engine = MonitoringEngine(providers: [healthy, flaky])
        let collector = EventCollector()
        let consumer = Task { for await event in engine.events { await collector.append(event) } }

        await engine.probeAll()
        await engine.sampleOnce(tier: .fast) // flaky fails
        await engine.sampleOnce(tier: .fast) // flaky skipped (backoff)
        await engine.sampleOnce(tier: .fast) // flaky recovers
        try? await Task.sleep(for: .milliseconds(100))
        consumer.cancel()

        #expect(await healthy.sampleCount == 3)
        #expect(await flaky.sampleCount == 2)
        let events = await collector.events
        let gpuStates: [CapabilityState] = events.compactMap {
            if case let .capability(.gpuUsage, state) = $0 { return state }
            return nil
        }
        #expect(gpuStates.contains(.temporarilyUnavailable))
        #expect(gpuStates.last == .available)
    }

    @Test func onlyMatchingTierIsSampled() async {
        let fast = StubProvider(id: "fast", tier: .fast)
        let slow = StubProvider(id: "slow", tier: .slow)
        let engine = MonitoringEngine(providers: [fast, slow])
        await engine.probeAll()
        await engine.sampleOnce(tier: .slow)
        #expect(await fast.sampleCount == 0)
        #expect(await slow.sampleCount == 1)
    }

    @Test func interactiveOnlyProvidersPauseInBackground() async {
        let processes = StubProvider(id: "processes", minimumDemand: .interactive)
        let cpu = StubProvider(id: "cpu")
        let engine = MonitoringEngine(providers: [processes, cpu])
        await engine.probeAll()
        await engine.setDemand(.background)
        await engine.sampleOnce(tier: .fast)
        #expect(await processes.sampleCount == 0)
        #expect(await cpu.sampleCount == 1)
        await engine.setDemand(.interactive)
        await engine.sampleOnce(tier: .fast)
        #expect(await processes.sampleCount >= 1)
        #expect(await cpu.preparedDemands == [.background, .interactive])
    }

    @Test func runningEngineDeliversData() async throws {
        let provider = StubProvider(id: "p")
        let engine = MonitoringEngine(providers: [provider], policy: SamplingPolicy(interactiveInterval: 0.05))
        await engine.start()
        try await Task.sleep(for: .milliseconds(300))
        await engine.suspend()
        let count = await provider.sampleCount
        #expect(count >= 3)
        try await Task.sleep(for: .milliseconds(200))
        #expect(await provider.sampleCount <= count + 1, "Suspended engine stops sampling")
    }
}

@Suite("Metrics store")
@MainActor
struct MetricsStoreTests {
    private let profile = HardwareProfile(
        modelIdentifier: "Test", marketingName: nil, computerName: nil, chipName: "Test", chipFamily: .unknown,
        architecture: .arm64, cpu: CPUTopology(physicalCores: 1, logicalCores: 1, performanceCores: nil, efficiencyCores: nil),
        gpuCoreCount: nil, physicalMemory: 1, operatingSystem: "", hasBattery: false, fanCount: 0
    )

    @Test func seriesKeepsFixedCapacityAndStatistics() {
        let store = MetricsStore(profile: profile, seriesCapacity: 3)
        for value in 1...5 { store.handle(.fragment(StubFragment(value: Double(value)))) }
        let series = store.series(for: .cpuUsage)
        #expect(series.samples.map(\.value) == [3, 4, 5])
        #expect(series.statistics?.minimum == 3)
        #expect(series.statistics?.mean == 4)
        #expect(store.snapshot.thermal?.level == .fair)
    }

    @Test func demoStoreTagsEveryReadingAsDemo() {
        let store = MetricsStore(profile: profile, isDemo: true)
        store.handle(.fragment(StubFragment(value: 1)))
        #expect(store.series(for: .cpuUsage).provenance == .demo)
    }

    @Test func capabilityUpdates() {
        let store = MetricsStore(profile: profile, staticCapabilities: [.fans: .unavailable])
        store.handle(.capability(.cpuUsage, .available))
        #expect(store.capabilities.isUsable(.cpuUsage))
        #expect(!store.capabilities.isPresent(.fans))
    }
}
