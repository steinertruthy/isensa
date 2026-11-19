import Foundation
import iSensaCore
import iSensaDesign
import iSensaMonitoring
import SwiftUI

/// Settings, organized like System Settings: hued sidebar icons, one grouped form per topic.
public struct SettingsView: View {
    @Environment(MetricsStore.self) private var store
    @State private var selection: SettingsPane?

    /// `-iSensaSettingsPane <name>` opens a specific pane (screenshots, UI tests).
    public init() {
        _selection = State(initialValue: UserDefaults.standard.string(forKey: "iSensaSettingsPane").flatMap(SettingsPane.init) ?? .general)
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsPane.groups(capabilities: store.capabilities), id: \.self) { group in
                    Section {
                        ForEach(group) { pane in
                            Label { Text(pane.title) } icon: { SidebarIcon(pane.symbol, hue: pane.hue, isSelected: selection == pane) }
                                .tag(pane)
                                .accessibilityIdentifier("settings.\(pane.rawValue)")
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 215, max: 240)
        } detail: {
            (selection ?? .general).view
                .formStyle(.grouped)
                .navigationTitle((selection ?? .general).title)
                // Panes swap without an animated overlap: two grouped forms (AppKit tables) on screen at
                // once, inside the main window's split view, could send the window's layout into a loop.
                .id(selection)
        }
        .frame(minWidth: 720, minHeight: 520)
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, appearance, sounds, overview, menuBar, monitoring, sensors, battery, fans, notifications, history, privacy, advanced, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: tr("General")
        case .appearance: tr("Appearance")
        case .sounds: tr("Sounds & Haptics")
        case .overview: tr("Overview")
        case .menuBar: tr("Menu Bar")
        case .monitoring: tr("Monitoring & Energy")
        case .sensors: tr("Sensors")
        case .battery: tr("Battery")
        case .fans: tr("Fans")
        case .notifications: tr("Notifications")
        case .history: tr("History")
        case .privacy: tr("Privacy")
        case .advanced: tr("Advanced")
        case .about: tr("About iSensa")
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush.pointed"
        case .sounds: "speaker.wave.2"
        case .overview: "square.grid.2x2"
        case .menuBar: "menubar.rectangle"
        case .monitoring: "speedometer"
        case .sensors: "sensor"
        case .battery: "battery.75percent"
        case .fans: "fan"
        case .notifications: "bell.badge"
        case .history: "clock.arrow.circlepath"
        case .privacy: "hand.raised"
        case .advanced: "wrench.and.screwdriver"
        case .about: "info.circle"
        }
    }

    var hue: Hue {
        switch self {
        case .general, .advanced, .about: .neutral
        case .appearance, .privacy: .cpu
        case .sounds: .gpu
        case .overview, .menuBar: .network
        case .monitoring: .memory
        case .sensors: .thermal
        case .battery: .battery
        case .fans: .fans
        case .notifications: .storage
        case .history: .power
        }
    }

    /// Battery and fan panes only exist on Macs that have them.
    static func groups(capabilities: CapabilityMap) -> [[SettingsPane]] {
        var hardware: [SettingsPane] = [.monitoring, .sensors]
        if capabilities.isPresent(.battery) { hardware.append(.battery) }
        if capabilities.isPresent(.fans) { hardware.append(.fans) }
        return [
            [.general, .appearance, .sounds],
            [.overview, .menuBar],
            hardware,
            [.notifications, .history, .privacy],
            [.advanced, .about]
        ]
    }

    @MainActor @ViewBuilder var view: some View {
        switch self {
        case .general: GeneralPane()
        case .appearance: AppearancePane()
        case .sounds: SoundsPane()
        case .overview: OverviewPane()
        case .menuBar: MenuBarSettings()
        case .monitoring: MonitoringPane()
        case .sensors: SensorsPane()
        case .battery: BatteryPane()
        case .fans: FansPane()
        case .notifications: NotificationsPane()
        case .history: HistoryPane()
        case .privacy: PrivacyPane()
        case .advanced: AdvancedPane()
        case .about: AboutPane()
        }
    }
}

/// Secondary explanatory line inside a form section.
struct Footnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}

/// An explanation with its action underneath. Text that wraps beside a button in a form row makes
/// AppKit recompute the window's layout in a loop (it crashed the app), so the button goes below.
struct FootnoteAction<Action: View>: View {
    let text: String
    @ViewBuilder let action: Action

    init(_ text: String, @ViewBuilder action: () -> Action) {
        self.text = text
        self.action = action()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Footnote(text)
            action
        }
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
