import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Main window: native sidebar that adapts to this Mac's capabilities, and the detail screen.
public struct RootView: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.services) private var services
    @Environment(\.sensaMotion) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Remembered between launches, like the sidebar of Finder or Mail.
    @AppStorage("sidebarVisible") private var sidebarVisible = true
    /// Drives the split view. A `@State` (not the stored preference directly) so the change carries
    /// the animation transaction: writes through `UserDefaults` arrive without it and snap.
    @State private var visibility: NavigationSplitViewVisibility?

    public init() {}

    public var body: some View {
        @Bindable var navigation = navigation
        let destinations = Destination.visible(in: store.capabilities)
        NavigationSplitView(columnVisibility: columnVisibility) {
            List(selection: $navigation.selection) {
                ForEach(Destination.Section.allCases, id: \.self) { section in
                    let items = destinations.filter { $0.section == section }
                    if !items.isEmpty {
                        if section == .summary {
                            Section { rows(items) }
                        } else {
                            Section(sectionTitle(section)) { rows(items) }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SidebarFooterButton(title: tr("Settings"), symbol: "gearshape", action: services.actions.openSettings)
                    .accessibilityIdentifier("sidebar.settings")
            }
            // One toggle, owned by Sensa, so its state can be remembered.
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            detail(for: navigation.selection ?? .overview)
                .sensaScreenTransition(id: navigation.selection)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    let collapse = columnVisibility.wrappedValue != .detailOnly
                    withAnimation(Motion.resolve(Motion.sidebar, preference: motion, reduceMotion: reduceMotion)) {
                        columnVisibility.wrappedValue = collapse ? .detailOnly : .all
                    }
                } label: {
                    Label(tr("Toggle Sidebar"), systemImage: "sidebar.left")
                }
                .help(tr("Toggle Sidebar"))
                .accessibilityIdentifier("toolbar.sidebar")
            }
        }
        .onChange(of: destinations) { _, visible in
            if let selection = navigation.selection, !visible.contains(selection) { navigation.selection = .overview }
        }
        .frame(minWidth: 820, minHeight: 560)
    }

    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { visibility ?? (sidebarVisible ? .all : .detailOnly) },
            set: { newValue in
                visibility = newValue
                sidebarVisible = newValue != .detailOnly
            }
        )
    }

    @ViewBuilder
    private func detail(for destination: Destination) -> some View {
        switch destination {
        case .overview: DashboardView(selection: Binding(get: { navigation.selection }, set: { navigation.selection = $0 }))
            .navigationTitle(tr("Overview"))
        case .cpu: CPUScreen().navigationTitle(tr("CPU"))
        case .gpu: GPUScreen().navigationTitle(tr("GPU"))
        case .memory: MemoryScreen().navigationTitle(tr("Memory"))
        case .battery: BatteryScreen().navigationTitle(tr("Battery"))
        case .thermals: ThermalsScreen().navigationTitle(tr("Temperatures"))
        case .fans: FansScreen().navigationTitle(tr("Fans"))
        case .storage: StorageScreen().navigationTitle(tr("Storage"))
        case .network: NetworkScreen().navigationTitle(tr("Network"))
        case .sensors: SensorExplorerScreen()
        case .history: HistoryScreen().navigationTitle(tr("History"))
        }
    }

    private func rows(_ items: [Destination]) -> some View {
        ForEach(items) { destination in
            Label { Text(destination.title) } icon: {
                SidebarIcon(destination.symbolName, hue: destination.hue, isSelected: navigation.selection == destination)
            }
                .tag(destination)
                .accessibilityIdentifier("sidebar.\(destination.rawValue)")
        }
    }

    private func sectionTitle(_ section: Destination.Section) -> String {
        switch section {
        case .summary: tr("Overview")
        case .components: tr("Components")
        case .thermal: tr("Cooling")
        case .advanced: tr("Advanced")
        }
    }
}
