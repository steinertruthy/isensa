import Foundation
import iSensaControl

/// Clearly-labelled demonstration of fan control: no helper, no hardware writes. Lets the interface
/// and UI tests exercise every state.
public actor DemoFanControlService: FanControlService {
    public nonisolated let isDemo = true
    private var installed: Bool
    private var status = HelperStatus()

    public init(installed: Bool = false) {
        self.installed = installed
    }

    public func state() -> FanHelperState { installed ? .ready(status) : .notInstalled }

    public func apply(_ targets: [FanTarget]) throws {
        guard installed else { throw FanControlFailure("Helper not installed") }
        status.isManual = true
        status.targets = targets
    }

    public func heartbeat() -> Bool { status.isManual }

    public func restoreAutomatic() {
        status = HelperStatus(lastRestore: .requested)
    }

    public func install() { installed = true }

    public func uninstall() {
        installed = false
        status = HelperStatus()
    }
}
