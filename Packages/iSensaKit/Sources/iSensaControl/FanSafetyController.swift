import Foundation

/// Hardware access the privileged helper needs. Implemented with SMC writes in the helper and with
/// fakes in tests.
public protocol FanHardware: AnyObject {
    /// Writes accepted since start (diagnostics).
    var writeCount: Int { get }
    /// Limits read from the hardware right now.
    func limits() throws -> [FanLimits]
    /// Puts the given fans under manual control at the given speeds.
    func setManual(_ targets: [FanTarget]) throws
    /// Hands every fan back to the firmware and verifies it took over.
    func restoreAutomatic() throws
}

/// Why the helper handed control back to macOS.
public enum RestoreReason: String, Codable, Sendable {
    case requested, leaseExpired, clientDisconnected, thermalPressure, helperStarted, helperStopping, error
}

public enum FanSafetyError: Error, Equatable, Sendable, CustomStringConvertible {
    case thermalGuard
    case hardware(String)

    public var description: String {
        switch self {
        case .thermalGuard: "Thermal guard active"
        case let .hardware(message): message
        }
    }
}

/// Snapshot of the helper's state, sent to the app.
public struct HelperStatus: Codable, Equatable, Sendable {
    public var isManual: Bool
    public var targets: [FanTarget]
    public var lastRestore: RestoreReason?
    public var thermalGuardActive: Bool
    public var lastError: String?
    /// SMC writes the firmware accepted since the helper started (some firmware limits them per boot).
    public var writeCount: Int

    public init(
        isManual: Bool = false, targets: [FanTarget] = [], lastRestore: RestoreReason? = nil,
        thermalGuardActive: Bool = false, lastError: String? = nil, writeCount: Int = 0
    ) {
        self.writeCount = writeCount
        self.isManual = isManual
        self.targets = targets
        self.lastRestore = lastRestore
        self.thermalGuardActive = thermalGuardActive
        self.lastError = lastError
    }
}

/// The helper's safety core. Owns every decision to write fans; independent of the app:
///
/// - a manual setting lives only as long as its **lease** (renewed by the app's heartbeat);
/// - a dropped connection, a stop signal and the helper's own start all **restore automatic**;
/// - serious or critical **thermal pressure** restores automatic and refuses manual control until
///   macOS reports normal conditions for `thermalCooldown`;
/// - every request is **validated** against limits read from the hardware at that moment.
///
/// Not thread-safe: the helper calls it from one serial queue.
public final class FanSafetyController {
    public static let leaseDuration: TimeInterval = 10
    public static let thermalCooldown: TimeInterval = 30

    private let hardware: FanHardware
    private let leaseDuration: TimeInterval
    private let thermalCooldown: TimeInterval
    private var leaseExpiry: Date?
    private var thermalClearSince: Date?
    private var state = HelperStatus()
    public var status: HelperStatus {
        var current = state
        current.writeCount = hardware.writeCount
        return current
    }

    public init(hardware: FanHardware, leaseDuration: TimeInterval = leaseDuration, thermalCooldown: TimeInterval = thermalCooldown) {
        self.hardware = hardware
        self.leaseDuration = leaseDuration
        self.thermalCooldown = thermalCooldown
    }

    /// Called when the helper launches — including after a crash or reboot mid-override.
    public func start() {
        restore(.helperStarted, force: true)
    }

    /// Applies targets after validation; starts or renews the lease.
    public func apply(_ targets: [FanTarget], now: Date) throws {
        guard !state.thermalGuardActive else { throw FanSafetyError.thermalGuard }
        let limits: [FanLimits]
        do { limits = try hardware.limits() } catch { throw FanSafetyError.hardware(String(describing: error)) }
        let validated = try FanCommandValidator.validate(targets, limits: limits)
        do {
            try hardware.setManual(validated)
        } catch {
            restore(.error, force: true)
            throw FanSafetyError.hardware(String(describing: error))
        }
        state.isManual = true
        state.targets = validated
        state.lastError = nil
        leaseExpiry = now.addingTimeInterval(leaseDuration)
    }

    /// Renews the lease. Returns `false` when nothing is under manual control.
    @discardableResult
    public func heartbeat(now: Date) -> Bool {
        guard state.isManual else { return false }
        leaseExpiry = now.addingTimeInterval(leaseDuration)
        return true
    }

    public func requestAutomatic() {
        restore(.requested, force: false)
    }

    public func clientDisconnected() {
        restore(.clientDisconnected, force: false)
    }

    public func stopping() {
        restore(.helperStopping, force: true)
    }

    /// Periodic check (about once a second): lease expiry and macOS thermal pressure.
    public func tick(now: Date, thermalPressureIsHigh: Bool) {
        if thermalPressureIsHigh {
            thermalClearSince = nil
            if !state.thermalGuardActive {
                state.thermalGuardActive = true
                restore(.thermalPressure, force: false)
            }
        } else if state.thermalGuardActive {
            let clearSince = thermalClearSince ?? now
            thermalClearSince = clearSince
            if now.timeIntervalSince(clearSince) >= thermalCooldown {
                state.thermalGuardActive = false
                thermalClearSince = nil
            }
        }
        if state.isManual, let leaseExpiry, now >= leaseExpiry {
            restore(.leaseExpired, force: false)
        }
    }

    /// `force` writes automatic even when iSensa believes nothing is overridden (start-up, stop,
    /// errors), in case another tool or a crash left a fan in manual mode.
    private func restore(_ reason: RestoreReason, force: Bool) {
        guard force || state.isManual else { return }
        do {
            try hardware.restoreAutomatic()
            state.lastError = nil
        } catch {
            state.lastError = String(describing: error)
        }
        state.isManual = false
        state.targets = []
        state.lastRestore = reason
        leaseExpiry = nil
    }
}
