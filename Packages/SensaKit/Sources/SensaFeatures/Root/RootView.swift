import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Main window: native sidebar that adapts to this Mac's capabilities, and the detail screen.
public struct RootView: View {
    @Environment(MetricsStore.self) private var store
    @State private var selection: Destination?

    public init(initialSelection: Destination = .overview) {
        _selection = State(initialValue: initialSelection)
    }

    public var body: some View {
        let destinations = Destination.visible(in: store.capabilities)
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Destination.Section.allCases, id: \.self) { section in
                    let items = destinations.filter { $0.section == section }
                    if !items.isEmpty {
                        Section(sectionTitle(section)) {
                            ForEach(items) { destination in
                                Label(destination.title, systemImage: destination.symbolName)
                                    .tag(destination)
                                    .accessibilityIdentifier("sidebar.\(destination.rawValue)")
                            }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        } detail: {
            detail(for: selection ?? .overview)
                .id(selection)
                .transition(.opacity)
        }
        .onChange(of: destinations) { _, visible in
            if let selection, !visible.contains(selection) { self.selection = .overview }
        }
        .frame(minWidth: 820, minHeight: 560)
    }

    @ViewBuilder
    private func detail(for destination: Destination) -> some View {
        switch destination {
        case .overview: DashboardView(selection: $selection).navigationTitle(tr("Overview"))
        case .cpu: CPUScreen().navigationTitle(tr("CPU"))
        case .gpu: GPUScreen().navigationTitle(tr("GPU"))
        case .memory: MemoryScreen().navigationTitle(tr("Memory"))
        case .battery: BatteryScreen().navigationTitle(tr("Battery"))
        case .thermals: ThermalsScreen().navigationTitle(tr("Temperatures"))
        case .fans: FansScreen().navigationTitle(tr("Fans"))
        case .storage: StorageScreen().navigationTitle(tr("Storage"))
        case .network: NetworkScreen().navigationTitle(tr("Network"))
        case .sensors: SensorExplorerScreen()
        }
    }

    private func sectionTitle(_ section: Destination.Section) -> String {
        switch section {
        case .summary: tr("Sensa")
        case .components: tr("Components")
        case .thermal: tr("Cooling")
        case .advanced: tr("Advanced")
        }
    }
}
