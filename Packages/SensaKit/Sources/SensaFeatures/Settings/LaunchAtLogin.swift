/// Abstraction over the system login-item service, implemented by the app layer.
@MainActor
public protocol LaunchAtLoginControlling: AnyObject {
    var isEnabled: Bool { get }
    /// Whether macOS asks the user to approve the login item in System Settings.
    var requiresApproval: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
