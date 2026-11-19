import Foundation

/// Names and paths shared by the app and the privileged helper.
public enum FanHelper {
    public static let label = "app.sensa.Sensa.helper"
    public static let machServiceName = label
    /// Bumped whenever the XPC interface or its semantics change; app and helper must match.
    public static let protocolVersion = 1
    public static let installedBinaryPath = "/Library/PrivilegedHelperTools/\(label)"
    public static let launchDaemonPath = "/Library/LaunchDaemons/\(label).plist"
    /// Location inside Sensa.app.
    public static let bundledRelativePath = "Contents/Library/LaunchServices/\(label)"
    /// How often the app renews its lease while it controls the fans (well inside the lease).
    public static let heartbeatInterval: TimeInterval = 3
}

/// XPC interface of the privileged helper. Payloads are JSON-encoded `Codable` values so the
/// interface stays small and versionable. Replies carry an error message, or `nil` on success.
@objc public protocol FanHelperXPC {
    func handshake(reply: @escaping @Sendable (Int) -> Void)
    func status(reply: @escaping @Sendable (Data?) -> Void)
    func apply(_ targets: Data, reply: @escaping @Sendable (String?) -> Void)
    func heartbeat(reply: @escaping @Sendable (Bool) -> Void)
    func restoreAutomatic(reply: @escaping @Sendable (String?) -> Void)
}
