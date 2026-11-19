import SensaCore
import SensaDesign
import SensaInsights
import SensaMonitoring
import SwiftUI

struct MonitoringPane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Refresh rate")) {
                Picker(tr("While a Sensa window is open"), selection: $settings.refreshInterval) {
                    Text(tr("Every second")).tag(1.0)
                    Text(tr("Every 2 seconds")).tag(2.0)
                    Text(tr("Every 5 seconds")).tag(5.0)
                }
                Picker(tr("When only the menu bar is visible"), selection: $settings.backgroundRefreshInterval) {
                    Text(tr("Every 2 seconds")).tag(2.0)
                    Text(tr("Every 3 seconds")).tag(3.0)
                    Text(tr("Every 5 seconds")).tag(5.0)
                    Text(tr("Every 10 seconds")).tag(10.0)
                }
                Footnote(tr("Temperatures and fans refresh at half this rate. Longer intervals use less energy."))
            }
            Section(tr("Energy")) {
                Toggle(tr("Refresh less often on battery power"), isOn: $settings.savesEnergyOnBattery)
                Footnote(Copy.energyExplanation)
            }
        }
    }
}

struct SensorsPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.feedback) private var feedback
    @State private var confirmClear = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Units")) {
                Picker(tr("Temperature"), selection: $settings.temperatureUnit) {
                    Text(tr("Celsius (°C)")).tag(TemperatureUnitPreference.celsius)
                    Text(tr("Fahrenheit (°F)")).tag(TemperatureUnitPreference.fahrenheit)
                }
                .pickerStyle(.segmented)
            }
            Section(tr("Sensor list")) {
                Toggle(tr("Show sensors Sensa cannot identify"), isOn: $settings.showsUnknownSensors)
                Footnote(tr("Unknown sensors keep their original key. Favorites are always shown."))
                LabeledContent(tr("Favorites"), value: "\(settings.favoriteSensors.count)")
                LabeledContent(tr("Renamed sensors"), value: "\(settings.sensorNicknames.count)")
                Button(tr("Clear favorites and names…")) { confirmClear = true }
                    .disabled(settings.favoriteSensors.isEmpty && settings.sensorNicknames.isEmpty)
            }
        }
        .confirmationDialog(tr("Clear favorites and names?"), isPresented: $confirmClear) {
            Button(tr("Clear"), role: .destructive) {
                settings.favoriteSensors = []
                settings.sensorNicknames = [:]
                feedback.perform(.confirm)
            }
        } message: {
            Text(tr("Sensors return to their original names and the favorites list is emptied."))
        }
    }
}

struct BatteryPane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                RuleToggle(rule: $settings.alerts.lowBattery, title: tr("When the battery is low"))
                ThresholdSlider(value: $settings.alerts.lowBattery.threshold, range: 0.05...0.5, step: 0.05) { Self.percent($0) }
                    .disabled(!settings.alerts.lowBattery.isEnabled)
                RuleToggle(rule: $settings.alerts.batteryCharged, title: tr("When charging reaches a level"))
                ThresholdSlider(value: $settings.alerts.batteryCharged.threshold, range: 0.5...1, step: 0.05) { Self.percent($0) }
                    .disabled(!settings.alerts.batteryCharged.isEnabled)
                RuleToggle(rule: $settings.alerts.batteryTemperature, title: tr("When the battery gets warm"))
                ThresholdSlider(value: $settings.alerts.batteryTemperature.threshold, range: 35...55, step: 1) {
                    settings.formatter.temperature($0)
                }
                .disabled(!settings.alerts.batteryTemperature.isEnabled)
            } header: {
                Text(tr("Alerts"))
            } footer: {
                if !settings.alerts.isEnabled { Footnote(tr("Turn on notifications in Settings › Notifications for these alerts to be sent.")) }
            }
            Section(tr("Charging")) {
                Footnote(Copy.chargeLimitNote)
            }
        }
    }

    static func percent(_ value: Double) -> String { value.formatted(.percent.precision(.fractionLength(0))) }
}

struct FansPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(MetricsStore.self) private var store

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Display")) {
                Picker(tr("Show fan speed as"), selection: $settings.fanSpeedDisplay) {
                    Text(tr("Revolutions per minute")).tag(FanSpeedDisplay.rpm)
                    Text(tr("Percentage of range")).tag(FanSpeedDisplay.percentOfRange)
                }
                Footnote(tr("Percentage of range places the current speed between the fan's minimum and maximum."))
            }
            Section(tr("Control")) {
                if case .requiresAuthorization? = store.capabilities[.fanControl] {
                    Label(tr("Fan control is locked"), systemImage: "lock.shield")
                    Footnote(Copy.fanControlLocked)
                } else {
                    Footnote(tr("Your Mac manages its fans automatically."))
                }
            }
        }
    }
}

/// Toggle bound to an alert rule's on/off state.
struct RuleToggle: View {
    @Binding var rule: AlertConfiguration.Rule
    let title: String

    var body: some View {
        Toggle(title, isOn: $rule.isEnabled)
    }
}

/// Slider for a rule threshold, with its formatted value.
struct ThresholdSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        LabeledContent(tr("Threshold")) {
            HStack {
                Slider(value: $value, in: range, step: step) { Text(tr("Threshold")) }.labelsHidden()
                Text(format(value)).monospacedDigit().frame(minWidth: 52, alignment: .trailing)
            }
            .frame(maxWidth: 260)
        }
    }
}
