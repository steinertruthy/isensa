import iSensaCore
import iSensaDesign

/// Sidebar destinations. Each declares the capability it needs, so the sidebar
/// adapts to the Mac (no battery on a Mac mini, no fans on a MacBook Air…).
public enum Destination: String, Hashable, CaseIterable, Identifiable, Sendable {
    case overview, cpu, gpu, memory, battery, thermals, fans, storage, network, sensors, history

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: tr("Overview")
        case .cpu: tr("CPU")
        case .gpu: tr("GPU")
        case .memory: tr("Memory")
        case .battery: tr("Battery")
        case .thermals: tr("Temperatures")
        case .fans: tr("Fans")
        case .storage: tr("Storage")
        case .network: tr("Network")
        case .sensors: tr("Sensors")
        case .history: tr("History")
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "gauge.with.dots.needle.50percent"
        case .cpu: "cpu"
        case .gpu: "square.stack.3d.up"
        case .memory: "memorychip"
        case .battery: "battery.75percent"
        case .thermals: "thermometer.medium"
        case .fans: "fan"
        case .storage: "internaldrive"
        case .network: "arrow.up.arrow.down"
        case .sensors: "sensor"
        case .history: "clock.arrow.circlepath"
        }
    }

    var hue: Hue {
        switch self {
        case .overview, .sensors, .history: .neutral
        case .cpu: .cpu
        case .gpu: .gpu
        case .memory: .memory
        case .battery: .battery
        case .thermals: .thermal
        case .fans: .fans
        case .storage: .storage
        case .network: .network
        }
    }

    /// Feature that must be present on this Mac for the destination to appear.
    var requiredFeature: Feature? {
        switch self {
        case .overview, .history: nil
        case .cpu: .cpuUsage
        case .gpu: .gpuUsage
        case .memory: .memory
        case .battery: .battery
        case .thermals: .thermalState
        case .fans: .fans
        case .storage: .storage
        case .network: .network
        case .sensors: .temperatureSensors
        }
    }

    enum Section: CaseIterable {
        case summary, components, thermal, advanced
    }

    var section: Section {
        switch self {
        case .overview: .summary
        case .cpu, .gpu, .memory, .battery, .storage, .network: .components
        case .thermals, .fans: .thermal
        case .sensors, .history: .advanced
        }
    }

    static func visible(in capabilities: CapabilityMap) -> [Destination] {
        allCases.filter { destination in
            guard let feature = destination.requiredFeature else { return true }
            return capabilities.isPresent(feature)
        }
    }
}
