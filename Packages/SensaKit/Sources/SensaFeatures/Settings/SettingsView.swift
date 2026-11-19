import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Preferences window, grouped by context.
public struct SettingsView: View {
    private let launchAtLogin: LaunchAtLoginControlling

    public init(launchAtLogin: LaunchAtLoginControlling) {
        self.launchAtLogin = launchAtLogin
    }

    public var body: some View {
        TabView {
            GeneralSettings(launchAtLogin: launchAtLogin)
                .tabItem { Label(tr("General"), systemImage: "gearshape") }
            AppearanceSettings()
                .tabItem { Label(tr("Appearance"), systemImage: "paintbrush") }
            MenuBarSettings()
                .tabItem { Label(tr("Menu Bar"), systemImage: "menubar.rectangle") }
            PrivacySettings()
                .tabItem { Label(tr("Privacy"), systemImage: "hand.raised") }
            AboutSettings()
                .tabItem { Label(tr("About"), systemImage: "info.circle") }
        }
        .frame(width: 560)
        .frame(minHeight: 420)
    }
}

private struct GeneralSettings: View {
    @Environment(AppSettings.self) private var settings
    let launchAtLogin: LaunchAtLoginControlling
    @State private var launchError: String?
    @State private var launchEnabled = false
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(tr("Open at login"), isOn: Binding(get: { launchEnabled }, set: { setLaunch($0) }))
                if launchAtLogin.requiresApproval {
                    Text(tr("Approve Sensa in System Settings › General › Login Items.")).font(.caption).foregroundStyle(.secondary)
                }
                if let launchError { Text(launchError).font(.caption).foregroundStyle(.red) }
                Toggle(tr("Hide Dock icon (menu bar only)"), isOn: $settings.hidesDockIcon)
                Text(tr("You can always reopen Sensa from its menu bar icon.")).font(.caption).foregroundStyle(.secondary)
            }
            Section(tr("Greeting")) {
                Toggle(tr("Greet me by my first name"), isOn: $settings.greetingUsesName)
                Text(tr("Uses the name of your macOS account. It never leaves your Mac.")).font(.caption).foregroundStyle(.secondary)
            }
            Section(tr("Monitoring")) {
                Picker(tr("Refresh while visible"), selection: $settings.refreshInterval) {
                    Text(tr("Every second")).tag(1.0)
                    Text(tr("Every 2 seconds")).tag(2.0)
                    Text(tr("Every 5 seconds")).tag(5.0)
                }
                Text(tr("Sensa samples less often when its windows are hidden and on battery power, to save energy."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button(tr("Reset all preferences…"), role: .destructive) { confirmReset = true }
            }
        }
        .formStyle(.grouped)
        .onAppear { launchEnabled = launchAtLogin.isEnabled }
        .confirmationDialog(tr("Reset all preferences?"), isPresented: $confirmReset) {
            Button(tr("Reset"), role: .destructive) { settings.resetToDefaults() }
        } message: {
            Text(tr("Favorites, sensor names and menu bar choices will be restored to their defaults."))
        }
    }

    private func setLaunch(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            launchError = nil
        } catch {
            launchError = tr("macOS did not allow this change: %@", error.localizedDescription)
        }
        launchEnabled = launchAtLogin.isEnabled
    }
}

private struct AppearanceSettings: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Picker(tr("Appearance"), selection: $settings.appearance) {
                Text(tr("Automatic")).tag(AppearancePreference.system)
                Text(tr("Light")).tag(AppearancePreference.light)
                Text(tr("Dark")).tag(AppearancePreference.dark)
            }
            .pickerStyle(.inline)
            Picker(tr("Temperature"), selection: $settings.temperatureUnit) {
                Text(tr("Celsius (°C)")).tag(TemperatureUnitPreference.celsius)
                Text(tr("Fahrenheit (°F)")).tag(TemperatureUnitPreference.fahrenheit)
            }
            Toggle(tr("Always show technical details"), isOn: $settings.showsTechnicalDetails)
        }
        .formStyle(.grouped)
    }
}

private struct MenuBarSettings: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                List {
                    ForEach($settings.menuBarItems) { $item in
                        HStack {
                            Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary).accessibilityHidden(true)
                            Toggle(isOn: $item.isEnabled) {
                                Label(MenuBarValues.title(for: item.indicator), systemImage: MenuBarValues.symbol(for: item.indicator))
                            }
                            Spacer()
                            Toggle(tr("Graph"), isOn: $item.showsSparkline).disabled(!item.isEnabled)
                                .toggleStyle(.checkbox)
                        }
                    }
                    .onMove { settings.menuBarItems.move(fromOffsets: $0, toOffset: $1) }
                }
                .frame(minHeight: 240)
            } header: {
                Text(tr("Indicators"))
            } footer: {
                Text(tr("Drag to reorder. With no indicator enabled, Sensa shows only its icon.")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct PrivacySettings: View {
    var body: some View {
        Form {
            Section {
                Label(tr("Everything stays on your Mac."), systemImage: "lock.shield").font(Typography.headline)
                Text(Copy.privacyStatement)
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AboutSettings: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        Form {
            Section {
                InfoRow(tr("Version"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                InfoRow(tr("Mac"), value: "\(store.profile.displayModelName) (\(store.profile.modelIdentifier))")
                InfoRow(tr("Chip"), value: store.profile.chipName)
                InfoRow(tr("macOS"), value: store.profile.operatingSystem)
            }
            Section(tr("Detected capabilities")) {
                ForEach(store.capabilities.probedFeatures, id: \.self) { feature in
                    InfoRow(CapabilityText.featureName(feature), value: CapabilityText.stateName(store.capabilities[feature]))
                }
            }
        }
        .formStyle(.grouped)
    }
}

enum CapabilityText {
    static func featureName(_ feature: Feature) -> String {
        switch feature {
        case .cpuUsage: tr("CPU usage")
        case .cpuFrequency: tr("CPU frequency")
        case .gpuUsage: tr("GPU usage")
        case .memory: tr("Memory")
        case .battery: tr("Battery")
        case .powerAdapter: tr("Power adapter")
        case .thermalState: tr("Thermal state")
        case .temperatureSensors: tr("Temperature sensors")
        case .fans: tr("Fans")
        case .fanControl: tr("Fan control")
        case .powerConsumption: tr("Power consumption")
        case .storage: tr("Storage")
        case .network: tr("Network")
        case .wifiDetails: tr("Wi-Fi details")
        case .processes: tr("Processes")
        }
    }

    static func stateName(_ state: CapabilityState?) -> String {
        switch state {
        case .available?: tr("Available")
        case .experimental?: tr("Experimental")
        case .requiresAuthorization?: tr("Requires authorization")
        case .unavailable?: tr("Not present")
        case .unsupported?: tr("Not supported")
        case .temporarilyUnavailable?: tr("Temporarily unavailable")
        case nil: tr("Not checked")
        }
    }
}
