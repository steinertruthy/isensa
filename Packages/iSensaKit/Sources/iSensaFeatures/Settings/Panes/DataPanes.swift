import iSensaCore
import iSensaDesign
import iSensaMonitoring
import SwiftUI

struct HistoryPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @Environment(\.feedback) private var feedback
    @State private var size: Int64?
    @State private var confirmDelete = false

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(tr("Record history"), isOn: $settings.historyEnabled)
                Picker(tr("Keep history for"), selection: $settings.historyRetention) {
                    Text(tr("1 day")).tag(HistoryRetention.day)
                    Text(tr("7 days")).tag(HistoryRetention.week)
                    Text(tr("30 days")).tag(HistoryRetention.month)
                    Text(tr("90 days")).tag(HistoryRetention.quarter)
                }
                .disabled(!settings.historyEnabled)
            } footer: {
                Footnote(tr("iSensa keeps one summary per minute for a week, then one per hour. Older data is deleted automatically."))
            }
            Section(tr("Data")) {
                LabeledContent(tr("Space used"), value: size.map { $0.formatted(.byteCount(style: .file)) } ?? "–")
                HStack {
                    Button(tr("Open History")) { services.actions.openMainWindow() }
                    Spacer()
                    Button(tr("Delete History…"), role: .destructive) { confirmDelete = true }
                }
            }
        }
        .task { size = await services.history?.storageSize() }
        .confirmationDialog(tr("Delete all history?"), isPresented: $confirmDelete) {
            Button(tr("Delete"), role: .destructive) {
                Task {
                    try? await services.history?.deleteAll()
                    size = await services.history?.storageSize()
                    feedback.perform(.confirm)
                }
            }
        } message: {
            Text(tr("Recorded metrics and alerts are removed from this Mac. This cannot be undone."))
        }
    }
}

struct PrivacyPane: View {
    @Environment(\.services) private var services

    var body: some View {
        Form {
            Section {
                Label(tr("Everything stays on your Mac."), systemImage: "lock.shield").font(Typography.headline)
                Footnote(Copy.privacyStatement)
            }
            Section(tr("Your data")) {
                LabeledContent(tr("Preferences and history"), value: "~/Library/Application Support/iSensa")
                Button(tr("Show in Finder")) { services.actions.revealDataFolder() }
            }
            Section(tr("Permissions")) {
                Footnote(tr("iSensa needs no special permission to monitor your Mac. It asks only for notifications, and only when you turn them on."))
            }
        }
    }
}

struct AdvancedPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(MetricsStore.self) private var store
    @Environment(\.services) private var services
    @Environment(\.feedback) private var feedback
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section(tr("Welcome")) {
                Button(tr("Show Welcome Again")) { services.actions.showOnboarding() }
            }
            Section(tr("Detected capabilities")) {
                ForEach(store.capabilities.probedFeatures, id: \.self) { feature in
                    LabeledContent(CapabilityText.featureName(feature), value: CapabilityText.stateName(store.capabilities[feature]))
                }
                Footnote(tr("Experimental features read undocumented macOS interfaces and may change with macOS updates."))
            }
            Section {
                Button(tr("Reset All Settings…"), role: .destructive) { confirmReset = true }
            } footer: {
                Footnote(tr("History is kept. Delete it in Settings › History."))
            }
        }
        .confirmationDialog(tr("Reset all settings?"), isPresented: $confirmReset) {
            Button(tr("Reset"), role: .destructive) {
                settings.resetToDefaults()
                feedback.perform(.confirm)
            }
        } message: {
            Text(tr("Appearance, menu bar, alerts, favorites and every other preference return to their defaults."))
        }
    }
}

struct AboutPane: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        Form {
            Section {
                HStack(spacing: Spacing.large) {
                    Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text("iSensa").font(Typography.title)
                        Text(tr("Version %@", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"))
                            .font(Typography.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xSmall)
            }
            Section(tr("This Mac")) {
                LabeledContent(tr("Model"), value: "\(store.profile.displayModelName) (\(store.profile.modelIdentifier))")
                LabeledContent(tr("Chip"), value: store.profile.chipName)
                LabeledContent(tr("Memory"), value: store.profile.physicalMemory.formatted(.byteCount(style: .memory)))
                LabeledContent(tr("macOS"), value: store.profile.operatingSystem)
            }
        }
    }
}
