import Foundation
import SensaCore
import notify

/// macOS' own thermal assessment (public `ProcessInfo` and `notify` APIs).
public struct ThermalStateProvider: MetricProvider {
    public let id = "thermal.state"
    public let feature = Feature.thermalState
    public let tier = SamplingTier.medium

    public init() {}

    public func probe() async -> CapabilityState { .available }

    public func sample() async throws -> any SnapshotFragment {
        let level: ThermalLevel = switch ProcessInfo.processInfo.thermalState {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .serious
        }
        return ThermalSnapshot(timestamp: Date(), level: level, pressure: Self.pressure())
    }

    /// `OSThermalNotification.h`: `kOSThermalNotificationPressureLevelName`.
    private static func pressure() -> ThermalPressure? {
        var token: Int32 = 0
        guard notify_register_check("com.apple.system.thermalpressurelevel", &token) == NOTIFY_STATUS_OK else { return nil }
        defer { notify_cancel(token) }
        var state: UInt64 = 0
        guard notify_get_state(token, &state) == NOTIFY_STATUS_OK else { return nil }
        // Kernel values: 0 nominal, 10 moderate, 20 heavy, 30 trapping, 40 sleeping.
        return ThermalPressure(rawValue: Int(state / 10))
    }
}
