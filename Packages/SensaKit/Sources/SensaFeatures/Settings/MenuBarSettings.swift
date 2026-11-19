import SensaDesign
import SwiftUI

/// Menu bar preferences: which indicators, in what order, and how they are drawn.
struct MenuBarSettings: View {
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
                .frame(minHeight: 260)
            } header: {
                Text(tr("Indicators"))
            } footer: {
                Text(tr("Drag to reorder. With no indicator enabled, Sensa shows only its icon.")).font(.caption).foregroundStyle(.secondary)
            }

            Section(tr("Appearance")) {
                Picker(tr("Layout"), selection: $settings.menuBarLayout) {
                    Text(tr("Side by side")).tag(MenuBarLayout.inline)
                    Text(tr("Stacked (compact)")).tag(MenuBarLayout.stacked)
                }
                Toggle(tr("Show icons"), isOn: $settings.menuBarShowsIcons)
                Picker(tr("Precision"), selection: $settings.menuBarDecimals) {
                    Text(tr("Whole numbers")).tag(0)
                    Text(tr("One decimal place")).tag(1)
                }
                Text(tr("Stacked places two indicators in one column, using about half the width when the menu bar is crowded."))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section(tr("Updates")) {
                Picker(tr("Refresh when only the menu bar is visible"), selection: $settings.backgroundRefreshInterval) {
                    Text(tr("Every 2 seconds")).tag(2.0)
                    Text(tr("Every 3 seconds")).tag(3.0)
                    Text(tr("Every 5 seconds")).tag(5.0)
                    Text(tr("Every 10 seconds")).tag(10.0)
                }
                Text(tr("Temperatures and fans refresh at half this rate. Longer intervals use less energy."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
