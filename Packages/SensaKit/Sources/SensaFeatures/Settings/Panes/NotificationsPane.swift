import AppKit
import SensaDesign
import SensaInsights
import SwiftUI

struct NotificationsPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @State private var authorization: NotificationAuthorization?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(tr("Send notifications"), isOn: Binding(get: { settings.alerts.isEnabled }, set: { enable($0) }))
                    .accessibilityIdentifier("settings.notifications.enabled")
                if authorization == .denied {
                    HStack {
                        Footnote(tr("Notifications for Sensa are turned off in System Settings."))
                        Spacer()
                        Button(tr("Open System Settings")) { openSystemNotifications() }
                    }
                }
                HStack {
                    Footnote(tr("Sensa only notifies when a condition lasts, then waits before repeating, so alerts stay rare."))
                    Spacer()
                    Button(tr("Send Test")) { services.alerts?.sendTestNotification() }
                        .disabled(!settings.alerts.isEnabled || authorization != .authorized)
                }
            }
            Section(tr("Alert me")) {
                RuleToggle(rule: $settings.alerts.highTemperature, title: AlertText.ruleName(.highTemperature))
                ThresholdSlider(value: $settings.alerts.highTemperature.threshold, range: 70...105, step: 1) { settings.formatter.temperature($0) }
                    .disabled(!settings.alerts.highTemperature.isEnabled)
                RuleToggle(rule: $settings.alerts.memoryPressure, title: AlertText.ruleName(.memoryPressure))
                RuleToggle(rule: $settings.alerts.lowStorage, title: AlertText.ruleName(.lowStorage))
                ThresholdSlider(value: $settings.alerts.lowStorage.threshold, range: 0.02...0.3, step: 0.01) {
                    tr("%@ free", BatteryPane.percent($0))
                }
                .disabled(!settings.alerts.lowStorage.isEnabled)
                RuleToggle(rule: $settings.alerts.ssdHealth, title: AlertText.ruleName(.ssdHealth))
                RuleToggle(rule: $settings.alerts.sensorUnavailable, title: AlertText.ruleName(.sensorUnavailable))
                if services.history != nil, settings.alerts.isEnabled {
                    Footnote(tr("Battery alerts are in Settings › Battery."))
                }
            }
            .disabled(!settings.alerts.isEnabled)
            Section(tr("Timing")) {
                Picker(tr("Condition must last"), selection: $settings.alerts.sustainedSeconds) {
                    Text(tr("30 seconds")).tag(30.0)
                    Text(tr("1 minute")).tag(60.0)
                    Text(tr("2 minutes")).tag(120.0)
                    Text(tr("5 minutes")).tag(300.0)
                }
                Picker(tr("Repeat at most every"), selection: $settings.alerts.repeatInterval) {
                    Text(tr("15 minutes")).tag(900.0)
                    Text(tr("30 minutes")).tag(1_800.0)
                    Text(tr("1 hour")).tag(3_600.0)
                    Text(tr("4 hours")).tag(14_400.0)
                }
            }
            .disabled(!settings.alerts.isEnabled)
        }
        .task { authorization = await services.notifications?.authorization() }
    }

    /// Turning notifications on asks macOS for permission the first time.
    private func enable(_ enabled: Bool) {
        guard enabled else {
            settings.alerts.isEnabled = false
            return
        }
        Task {
            let granted = await services.notifications?.requestAuthorization() ?? false
            authorization = await services.notifications?.authorization()
            settings.alerts.isEnabled = granted
        }
    }

    private func openSystemNotifications() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
