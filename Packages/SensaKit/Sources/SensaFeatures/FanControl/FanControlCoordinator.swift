import Foundation
import Observation
import SensaControl
import SensaCore
import SensaMonitoring

/// Something that went wrong, with the technical detail from the helper or macOS.
public enum FanControlProblem: Equatable, Sendable {
    /// The helper or the firmware refused manual control; macOS keeps control.
    case notApplied(String)
    case installFailed(String)
    case removeFailed(String)
    /// Returning the fans to automatic reported an error.
    case restoreFailed(String)

    public var detail: String {
        switch self {
        case let .notApplied(detail), let .installFailed(detail), let .removeFailed(detail), let .restoreFailed(detail): detail
        }
    }
}

/// Runs the fan mode the user chose: plans from the latest readings, talks to the privileged helper
/// and keeps its lease alive. Whenever anything is uncertain it hands control back to macOS.
@MainActor
@Observable
public final class FanControlCoordinator {
    public private(set) var helperState: FanHelperState = .notInstalled
    /// What is in effect right now.
    public private(set) var plan: FanPlan = .system(.userChoice)
    public private(set) var problem: FanControlProblem?
    public private(set) var isInstalling = false
    /// Switching to manual can take several seconds on M3 and later.
    public private(set) var isApplying = false
    /// So can handing the fans back to macOS.
    public private(set) var isReleasing = false
    /// What curves follow: the hottest CPU core, smoothed over a few seconds.
    public private(set) var controlTemperature: Double?

    @ObservationIgnored public let service: any FanControlService
    @ObservationIgnored private let store: MetricsStore
    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var planner = FanControlPlanner()
    @ObservationIgnored private var smoother = TemperatureSmoother()
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var sentTargets: [FanTarget] = []
    @ObservationIgnored private var isSuspended = false
    /// The mode whose application failed. Not retried automatically — each attempt costs firmware
    /// writes — until the user changes the mode or asks to try again.
    @ObservationIgnored private var refusedMode: FanMode?

    /// Re-send targets that moved by more than this, or at least this often.
    static let resendThresholdRPM: Double = 50
    static let tickInterval: Duration = .seconds(2)

    public init(service: any FanControlService, store: MetricsStore, settings: AppSettings) {
        self.service = service
        self.store = store
        self.settings = settings
    }

    public var isManual: Bool { if case .manual = plan { true } else { false } }

    public var isHelperReady: Bool { if case .ready = helperState { true } else { false } }

    public func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            await self?.refreshState()
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: Self.tickInterval)
            }
        }
    }

    /// Sleep and quit: hand control back to macOS and stop sending.
    public func suspend() async {
        isSuspended = true
        await releaseControl()
    }

    public func resume() {
        isSuspended = false
        planner = FanControlPlanner()
        smoother.reset()
    }

    public func refreshState() async {
        // While the helper is busy switching modes, a status query could time out: keep the last state.
        guard !isApplying, !isReleasing else { return }
        helperState = await service.state()
    }

    public func installHelper() async {
        isInstalling = true
        defer { isInstalling = false }
        do {
            try await service.install()
            problem = nil
        } catch is CancellationError {
            // The user dismissed the password prompt.
        } catch {
            problem = .installFailed(String(describing: error))
        }
        await refreshState()
    }

    public func uninstallHelper() async {
        await releaseControl()
        do {
            try await service.uninstall()
            problem = nil
        } catch is CancellationError {
        } catch {
            problem = .removeFailed(String(describing: error))
        }
        settings.fanMode = .automatic
        await refreshState()
    }

    /// One control step. Public for tests.
    public func tick(now: Date = Date()) async {
        guard !isSuspended else { return }
        updateControlTemperature()
        let mode = settings.fanMode
        guard mode.isManual else {
            if isManual || !sentTargets.isEmpty { await releaseControl() }
            plan = .system(.userChoice)
            refusedMode = nil
            return
        }
        if let refusedMode {
            guard !Self.sameKind(refusedMode, mode) else { return }
            self.refusedMode = nil
        }
        if !isHelperReady {
            await refreshState()
            guard isHelperReady else {
                plan = .system(.userChoice)
                return
            }
        }
        let sensors = store.snapshot.sensors
        let limits = (sensors?.fans ?? []).compactMap { fan -> FanLimits? in
            guard let minimum = fan.minimumRPM, let maximum = fan.maximumRPM else { return nil }
            return FanLimits(index: fan.id, minimumRPM: minimum, maximumRPM: maximum)
        }
        let next = planner.plan(
            mode: mode,
            temperature: controlTemperature,
            sampleAge: sensors.map { now.timeIntervalSince($0.timestamp) } ?? .infinity,
            thermalLevel: store.snapshot.thermal?.level,
            limits: limits,
            now: now
        )
        switch next {
        case .system:
            if !sentTargets.isEmpty { await releaseControl() }
            plan = next
        case let .manual(targets):
            await send(targets, now: now)
        }
    }

    private func updateControlTemperature() {
        guard let sensors = store.snapshot.sensors, let hottest = sensors.cpuHottestTemperature ?? sensors.cpuTemperature else { return }
        let smoothed = smoother.update(hottest, at: sensors.timestamp)
        if smoothed != controlTemperature { controlTemperature = smoothed }
    }

    /// Sends targets only when they change (the helper's lease is kept alive by heartbeats), so the
    /// firmware sees as few writes as possible.
    private func send(_ targets: [FanTarget], now: Date) async {
        let changed = targets.count != sentTargets.count
            || zip(targets, sentTargets).contains { abs($0.rpm - $1.rpm) > Self.resendThresholdRPM || $0.index != $1.index }
        do {
            if changed {
                isApplying = sentTargets.isEmpty
                defer { isApplying = false }
                try await service.apply(targets)
                sentTargets = targets
            } else if await !service.heartbeat() {
                // The helper dropped the setting (lease, thermal guard): apply again next time.
                sentTargets = []
            }
            plan = .manual(targets)
            problem = nil
        } catch {
            sentTargets = []
            plan = .system(.userChoice)
            problem = .notApplied(String(describing: error))
            refusedMode = settings.fanMode
            await refreshState()
        }
    }

    /// Clears a refusal so the next step tries again.
    public func retry() async {
        refusedMode = nil
        problem = nil
        await tick()
    }

    /// Moving the slider or switching preset is not a new attempt; switching mode is.
    static func sameKind(_ lhs: FanMode, _ rhs: FanMode) -> Bool {
        switch (lhs, rhs) {
        case (.fixed, .fixed), (.curve, .curve), (.custom, .custom), (.curve, .custom), (.custom, .curve), (.automatic, .automatic): true
        default: false
        }
    }

    private func releaseControl() async {
        sentTargets = []
        plan = .system(.userChoice)
        guard isHelperReady else { return }
        isReleasing = true
        defer { isReleasing = false }
        do {
            try await service.restoreAutomatic()
            if case .restoreFailed? = problem { problem = nil }
        } catch {
            problem = .restoreFailed(String(describing: error))
        }
    }
}
