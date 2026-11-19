import iSensaDesign
import SwiftUI

struct GeneralPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @State private var launchEnabled = false
    @State private var launchError: String?

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Startup")) {
                Toggle(tr("Open iSensa at login"), isOn: Binding(get: { launchEnabled }, set: { setLaunch($0) }))
                    .disabled(services.launchAtLogin == nil)
                if services.launchAtLogin?.requiresApproval == true {
                    Footnote(tr("Approve iSensa in System Settings › General › Login Items."))
                }
                if let launchError { Text(launchError).font(.caption).foregroundStyle(.red) }
                Toggle(tr("Show the window when iSensa opens"), isOn: $settings.opensWindowAtLaunch)
                Toggle(tr("Hide Dock icon (menu bar only)"), isOn: $settings.hidesDockIcon)
                Footnote(tr("You can always reopen iSensa from its menu bar icon."))
            }
            Section(tr("Language")) {
                Picker(tr("Language"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                }
                if settings.needsRelaunchForLanguage {
                    FootnoteAction(tr("The new language applies after iSensa restarts.")) {
                        Button(tr("Restart Now")) { services.actions.relaunch() }
                    }
                } else {
                    Footnote(tr("By default iSensa follows the language order in System Settings › General › Language & Region."))
                }
            }
            Section(tr("Greeting")) {
                Toggle(tr("Greet me by my first name"), isOn: $settings.greetingUsesName)
                Footnote(tr("Uses the name of your macOS account. It never leaves your Mac."))
            }
        }
        .onAppear { launchEnabled = services.launchAtLogin?.isEnabled ?? false }
    }

    private func setLaunch(_ enabled: Bool) {
        guard let service = services.launchAtLogin else { return }
        do {
            try service.setEnabled(enabled)
            launchError = nil
        } catch {
            launchError = tr("macOS did not allow this change: %@", error.localizedDescription)
        }
        launchEnabled = service.isEnabled
    }
}

struct AppearancePane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Theme")) {
                Picker(tr("Appearance"), selection: $settings.appearance) {
                    Text(tr("Automatic")).tag(AppearancePreference.system)
                    Text(tr("Light")).tag(AppearancePreference.light)
                    Text(tr("Dark")).tag(AppearancePreference.dark)
                }
                .pickerStyle(.segmented)
            }
            Section(tr("Animations")) {
                Picker(tr("Motion"), selection: $settings.motion) {
                    Text(tr("Full")).tag(MotionPreference.full)
                    Text(tr("Reduced")).tag(MotionPreference.reduced)
                    Text(tr("Off")).tag(MotionPreference.off)
                }
                .pickerStyle(.segmented)
                Footnote(reduceMotion
                    ? tr("Reduce Motion is on in System Settings, so iSensa uses short fades instead of movement.")
                    : tr("Reduced replaces movement with short fades. Off shows changes instantly."))
            }
            Section(tr("Detail")) {
                Toggle(tr("Always show technical details"), isOn: $settings.showsTechnicalDetails)
                Footnote(tr("Shows sensor sources, raw capacities and other advanced values on every screen."))
            }
        }
    }
}

struct SoundsPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.feedback) private var feedback

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section(tr("Sounds")) {
                Toggle(tr("Play sound effects"), isOn: $settings.soundsEnabled)
                LabeledContent(tr("Volume")) {
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary).accessibilityHidden(true)
                        Slider(value: $settings.soundVolume, in: 0.1...1) { Text(tr("Volume")) }
                            .labelsHidden()
                            .frame(maxWidth: 200)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary).accessibilityHidden(true)
                    }
                }
                .disabled(!settings.soundsEnabled)
                FootnoteAction(Copy.soundsExplanation) {
                    Button(tr("Preview")) { feedback.perform(.confirm) }.disabled(!settings.soundsEnabled)
                }
            }
            Section(tr("Haptics")) {
                Toggle(tr("Haptic feedback on the trackpad"), isOn: $settings.hapticsEnabled)
                Footnote(tr("A light tap when you mark a favorite or confirm an action, on Force Touch trackpads."))
            }
        }
    }
}

struct OverviewPane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        Form {
            Section {
                ForEach(DashboardCellKind.allCases) { kind in
                    Toggle(isOn: Binding(
                        get: { !settings.hiddenDashboardCells.contains(kind) },
                        set: { visible in
                            if visible { settings.hiddenDashboardCells.remove(kind) } else { settings.hiddenDashboardCells.insert(kind) }
                        }
                    )) {
                        Label { Text(Self.title(kind)) } icon: { SidebarIcon(Self.symbol(kind), hue: Self.hue(kind)) }
                    }
                }
            } header: {
                Text(tr("Show on the overview"))
            } footer: {
                Footnote(tr("Items this Mac does not have, such as a battery or fans, never appear."))
            }
        }
    }

    static func title(_ kind: DashboardCellKind) -> String {
        switch kind {
        case .cpu: tr("CPU")
        case .gpu: tr("GPU")
        case .memory: tr("Memory")
        case .temperature: tr("Temperature")
        case .power: tr("Power")
        case .fans: tr("Fans")
        case .battery: tr("Battery")
        case .storage: tr("Storage")
        case .network: tr("Network")
        }
    }

    static func symbol(_ kind: DashboardCellKind) -> String {
        switch kind {
        case .cpu: "cpu"
        case .gpu: "square.stack.3d.up"
        case .memory: "memorychip"
        case .temperature: "thermometer.medium"
        case .power: "bolt"
        case .fans: "fan"
        case .battery: "battery.75percent"
        case .storage: "internaldrive"
        case .network: "arrow.up.arrow.down"
        }
    }

    static func hue(_ kind: DashboardCellKind) -> Hue {
        switch kind {
        case .cpu: .cpu
        case .gpu: .gpu
        case .memory: .memory
        case .temperature: .thermal
        case .power: .power
        case .fans: .fans
        case .battery: .battery
        case .storage: .storage
        case .network: .network
        }
    }
}
