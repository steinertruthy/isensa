import Foundation

/// Where the privileged helper stands, from the app's point of view.
public enum FanHelperState: Equatable, Sendable {
    case notInstalled
    /// Installed, but not the build bundled with this copy of Sensa (or an older protocol).
    case needsUpdate
    /// Installed and answering.
    case ready(HelperStatus)
    /// Installed but not answering (e.g. still starting, or blocked by macOS).
    case unreachable(String)
}

/// The app's access to fan control. Production talks XPC to the helper; demo and tests use fakes.
public protocol FanControlService: Sendable {
    /// `true` for the clearly-labelled demonstration service.
    var isDemo: Bool { get }
    func state() async -> FanHelperState
    func apply(_ targets: [FanTarget]) async throws
    /// Renews the lease; `false` if the helper no longer holds a manual setting.
    func heartbeat() async -> Bool
    func restoreAutomatic() async throws
    /// Installs or updates the helper (asks for an administrator password).
    func install() async throws
    func uninstall() async throws
}

public struct FanControlFailure: Error, Equatable, Sendable, CustomStringConvertible {
    public let description: String
    public init(_ description: String) { self.description = description }
}
