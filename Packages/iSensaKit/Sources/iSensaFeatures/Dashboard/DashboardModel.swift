import iSensaCore
import iSensaDesign
import iSensaMonitoring

/// Overview cells the user can show or hide (Settings › Personalization).
public enum DashboardCellKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case cpu, gpu, memory, temperature, power, fans, battery, storage, network

    public var id: String { rawValue }
}

/// What the overview shows, as plain values: groups of cells, built only from data this Mac
/// actually provides and the user has not hidden. Pure and testable.
struct DashboardGroup: Identifiable, Equatable {
    let id: String
    let title: String
    let cells: [DashboardCell]
}

struct DashboardCell: Identifiable, Equatable {
    let kind: DashboardCellKind
    let destination: Destination
    let title: String
    let symbol: String
    let hue: Hue
    let value: String
    let caption: String
    let level: HealthLevel?
    let metric: MetricID
    let range: ClosedRange<Double>?

    var id: DashboardCellKind { kind }
}

@MainActor
enum DashboardModel {
    static func groups(
        store: MetricsStore, formatter: MetricFormatter, hidden: Set<DashboardCellKind>, fanDisplay: FanSpeedDisplay = .rpm
    ) -> [DashboardGroup] {
        let cells = allCells(store: store, formatter: formatter, fanDisplay: fanDisplay).filter { !hidden.contains($0.kind) }
        func group(_ id: String, _ title: String, _ kinds: [DashboardCellKind]) -> DashboardGroup? {
            let members = kinds.compactMap { kind in cells.first { $0.kind == kind } }
            return members.isEmpty ? nil : DashboardGroup(id: id, title: title, cells: members)
        }
        return [
            group("performance", tr("Performance"), [.cpu, .gpu, .memory]),
            group("thermals", tr("Thermals and power"), [.temperature, .power, .fans]),
            group("resources", tr("Battery, storage and network"), [.battery, .storage, .network])
        ].compactMap { $0 }
    }

    private static func allCells(store: MetricsStore, formatter: MetricFormatter, fanDisplay: FanSpeedDisplay) -> [DashboardCell] {
        let snapshot = store.snapshot
        var cells: [DashboardCell] = []
        func add(_ kind: DashboardCellKind, _ destination: Destination, _ identity: (title: String, symbol: String, hue: Hue), _ content: CellContent) {
            cells.append(DashboardCell(
                kind: kind, destination: destination, title: identity.title, symbol: identity.symbol, hue: identity.hue,
                value: content.value, caption: content.caption, level: content.level, metric: content.metric, range: content.range
            ))
        }

        if let cpu = snapshot.cpu {
            add(.cpu, .cpu, (tr("CPU"), "cpu", .cpu), CellContent(value: formatter.percent(cpu.totalUsage),
                caption: Descriptions.cpuLoad(cpu.totalUsage), metric: .cpuUsage, range: 0...1))
        }
        if let gpu = snapshot.gpu {
            add(.gpu, .gpu, (tr("GPU"), "square.stack.3d.up", .gpu), CellContent(value: formatter.percent(gpu.deviceUtilization),
                caption: Descriptions.cpuLoad(gpu.deviceUtilization), metric: .gpuUsage, range: 0...1))
        }
        if let memory = snapshot.memory {
            add(.memory, .memory, (tr("Memory"), "memorychip", .memory), CellContent(value: formatter.bytes(memory.used),
                caption: Descriptions.memoryPressure(memory.pressure), level: Descriptions.memoryLevel(memory.pressure),
                metric: .memoryUsed))
        }
        if let thermal = snapshot.thermal {
            let temperature = snapshot.sensors?.cpuTemperature
            add(.temperature, .thermals, (tr("Temperature"), "thermometer.medium", .thermal), CellContent(
                value: temperature.map { formatter.temperature($0) } ?? Descriptions.thermalShort(thermal.level),
                caption: Descriptions.thermal(thermal.level), level: Descriptions.thermalLevel(thermal.level),
                metric: .cpuTemperature))
        }
        if let power = snapshot.sensors?.systemPower {
            add(.power, .thermals, (tr("Power"), "bolt", .power), CellContent(value: formatter.watts(power),
                caption: tr("Total system power draw"), metric: .systemPower))
        }
        if store.capabilities.isPresent(.fans), let fans = snapshot.sensors?.fans, !fans.isEmpty {
            let fastest = fans.max { $0.currentRPM < $1.currentRPM }
            add(.fans, .fans, (tr("Fans"), "fan", .fans), CellContent(value: fastest.map { FanFormatting.value(
                $0,
                display: fanDisplay,
                formatter: formatter
            ) } ?? "–",
                caption: Descriptions.fans(fans), metric: .fanSpeed(0)))
        }
        if store.capabilities.isPresent(.battery), let battery = snapshot.battery {
            add(.battery, .battery, (tr("Battery"), batterySymbol(battery), .battery), CellContent(value: formatter.percent(battery.charge),
                caption: batteryCaption(battery, formatter: formatter), metric: .batteryCharge, range: 0...1))
        }
        if let root = snapshot.storage?.rootVolume {
            add(.storage, .storage, (tr("Storage"), "internaldrive", .storage), CellContent(value: formatter.fileBytes(root.availableCapacity),
                caption: tr("available of %@", formatter.fileBytes(root.totalCapacity)),
                level: root.usedFraction >= 0.9 ? .attention : nil, metric: .diskWrite))
        }
        if let network = snapshot.network {
            add(.network, .network, (tr("Network"), "arrow.up.arrow.down", .network), CellContent(value: formatter.rate(network.downloadRate ?? 0),
                caption: tr("Upload %@", formatter.rate(network.uploadRate ?? 0)), metric: .networkDownload))
        }
        return cells
    }

    /// The variable part of a cell.
    struct CellContent {
        var value: String
        var caption: String
        var level: HealthLevel?
        var metric: MetricID
        var range: ClosedRange<Double>?
    }

    nonisolated static func batterySymbol(_ battery: BatterySnapshot) -> String {
        if battery.state == .charging { return "battery.100percent.bolt" }
        return switch battery.charge {
        case ..<0.13: "battery.0percent"
        case ..<0.38: "battery.25percent"
        case ..<0.63: "battery.50percent"
        case ..<0.88: "battery.75percent"
        default: "battery.100percent"
        }
    }

    static func batteryCaption(_ battery: BatterySnapshot, formatter: MetricFormatter) -> String {
        if let minutes = battery.timeToEmpty { return tr("%@ remaining", formatter.duration(minutes: minutes)) }
        if let minutes = battery.timeToFull { return tr("Full in %@", formatter.duration(minutes: minutes)) }
        return Descriptions.chargeState(battery)
    }
}
