import Foundation

/// Explicit availability of a feature on this Mac, discovered at runtime — never assumed
/// from the processor family alone.
public enum CapabilityState: Sendable, Hashable, Codable {
    /// Works through a stable, verified interface.
    case available
    /// Works, but relies on undocumented interfaces or mappings not yet verified on this model.
    case experimental(ExperimentalReason)
    /// Supported by the hardware, but requires something the user must grant.
    case requiresAuthorization(AuthorizationRequirement)
    /// The hardware simply is not there (e.g. no battery on a Mac mini).
    case unavailable
    /// The hardware exists but this Mac / macOS version does not expose it.
    case unsupported
    /// Worked before, failing right now (e.g. read error after wake). Retried automatically.
    case temporarilyUnavailable

    /// Whether data for the feature can currently be shown.
    public var isUsable: Bool {
        switch self {
        case .available, .experimental: true
        case .requiresAuthorization, .unavailable, .unsupported, .temporarilyUnavailable: false
        }
    }

    /// Whether the UI should keep a place for the feature (hardware exists).
    public var isPresent: Bool {
        switch self {
        case .unavailable, .unsupported: false
        default: true
        }
    }
}

public enum ExperimentalReason: String, Sendable, Hashable, Codable {
    /// Read through an undocumented macOS interface that may change between releases.
    case privateInterface
    /// Sensor identification not yet verified on this Mac model.
    case unverifiedMapping
}

public enum AuthorizationRequirement: String, Sendable, Hashable, Codable {
    /// Privileged helper needs a Developer ID–signed app to be registered.
    case signedPrivilegedHelper
    /// The user must approve the helper in System Settings › Login Items.
    case helperApproval
    /// Location Services (needed by macOS to reveal Wi-Fi network names).
    case locationServices
    case notifications
}
