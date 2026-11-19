import iSensaFeatures
import ServiceManagement

/// `SMAppService.mainApp` — the modern, sandbox-friendly login item API (macOS 13+).
@MainActor
final class LaunchAtLoginService: LaunchAtLoginControlling {
    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    var requiresApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
