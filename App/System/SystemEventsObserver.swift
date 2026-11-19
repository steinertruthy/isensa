import AppKit
import IOKit.ps

/// Bridges system events to the app: sleep/wake (pause sampling), display sleep
/// (lower demand) and power source changes (longer intervals on battery).
@MainActor
final class SystemEventsObserver {
    private var tokens: [NSObjectProtocol] = []
    private var powerSource: CFRunLoopSource?
    private let onPowerSourceChange: @MainActor (Bool) -> Void

    init(
        onSleep: @escaping @MainActor () -> Void,
        onWake: @escaping @MainActor () -> Void,
        onScreensSleepChange: @escaping @MainActor (Bool) -> Void,
        onPowerSourceChange: @escaping @MainActor (Bool) -> Void
    ) {
        self.onPowerSourceChange = onPowerSourceChange
        let center = NSWorkspace.shared.notificationCenter
        func observe(_ name: Notification.Name, _ action: @escaping @MainActor () -> Void) -> NSObjectProtocol {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in MainActor.assumeIsolated { action() } }
        }
        tokens = [
            observe(NSWorkspace.willSleepNotification, onSleep),
            observe(NSWorkspace.didWakeNotification, onWake),
            observe(NSWorkspace.screensDidSleepNotification) { onScreensSleepChange(true) },
            observe(NSWorkspace.screensDidWakeNotification) { onScreensSleepChange(false) }
        ]
        installPowerSourceObserver()
        onPowerSourceChange(Self.isOnBattery())
    }

    // Lives for the whole app session; no teardown needed.

    static func isOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String? else { return false }
        return type == kIOPMBatteryPowerKey
    }

    private func installPowerSourceObserver() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let observer = Unmanaged<SystemEventsObserver>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { observer.onPowerSourceChange(SystemEventsObserver.isOnBattery()) }
        }, context)?.takeRetainedValue() else { return }
        powerSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }
}
