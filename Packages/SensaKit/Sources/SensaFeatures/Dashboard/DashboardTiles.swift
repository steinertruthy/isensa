import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Builds the dashboard tiles that this Mac can actually show.
@MainActor
enum DashboardTiles {
    struct Tile: Identifiable {
        let id: String
        let destination: Destination
        let view: AnyView
    }

    static func make(store: MetricsStore, formatter: MetricFormatter) -> [Tile] {
        let snapshot = store.snapshot
        let capabilities = store.capabilities
        var tiles: [Tile] = []

        if let cpu = snapshot.cpu {
            tiles.append(tile(.cpu, MetricTile(
                title: tr("CPU"), symbol: "cpu", value: formatter.percent(cpu.totalUsage),
                caption: Descriptions.cpuLoad(cpu.totalUsage)
            ) { SeriesSparkline(metric: .cpuUsage, range: 0...1, tint: .blue) }))
        }
        if let gpu = snapshot.gpu {
            tiles.append(tile(.gpu, MetricTile(
                title: tr("GPU"), symbol: "square.stack.3d.up", value: formatter.percent(gpu.deviceUtilization),
                caption: Descriptions.cpuLoad(gpu.deviceUtilization)
            ) { SeriesSparkline(metric: .gpuUsage, range: 0...1, tint: .purple) }))
        }
        if let memory = snapshot.memory {
            tiles.append(tile(.memory, MetricTile(
                title: tr("Memory"), symbol: "memorychip", value: formatter.bytes(memory.used),
                caption: Descriptions.memoryPressure(memory.pressure), level: Descriptions.memoryLevel(memory.pressure)
            ) { SeriesSparkline(metric: .memoryPressure, range: 0...1, tint: .green) }))
        }
        if let thermal = snapshot.thermal {
            let temperature = snapshot.sensors?.cpuTemperature
            tiles.append(tile(.thermals, MetricTile(
                title: tr("Temperature"), symbol: "thermometer.medium",
                value: temperature.map { formatter.temperature($0) } ?? tr("Normal"),
                caption: Descriptions.thermal(thermal.level), level: Descriptions.thermalLevel(thermal.level)
            ) {
                if temperature != nil { SeriesSparkline(metric: .cpuTemperature, tint: .orange) }
            }))
        }
        if capabilities.isPresent(.battery), let battery = snapshot.battery {
            tiles.append(tile(.battery, MetricTile(
                title: tr("Battery"), symbol: batterySymbol(battery), value: formatter.percent(battery.charge),
                caption: batteryCaption(battery, formatter: formatter)
            ) { SeriesSparkline(metric: .batteryCharge, range: 0...1, tint: .green) }))
        }
        if let power = snapshot.sensors?.systemPower {
            tiles.append(tile(.thermals, MetricTile(
                title: tr("Power"), symbol: "bolt", value: formatter.watts(power),
                caption: tr("Total system power draw")
            ) { SeriesSparkline(metric: .systemPower, tint: .yellow) }, id: "power"))
        }
        if capabilities.isPresent(.fans), let fans = snapshot.sensors?.fans, !fans.isEmpty {
            let fastest = fans.map(\.currentRPM).max() ?? 0
            tiles.append(tile(.fans, MetricTile(
                title: tr("Fans"), symbol: "fan", value: formatter.rpm(fastest), caption: Descriptions.fans(fans)
            ) { SeriesSparkline(metric: .fanSpeed(0), tint: .teal) }))
        }
        if let root = snapshot.storage?.rootVolume {
            tiles.append(tile(.storage, MetricTile(
                title: tr("Storage"), symbol: "internaldrive", value: formatter.fileBytes(root.availableCapacity),
                caption: tr("available of %@", formatter.fileBytes(root.totalCapacity)),
                level: root.usedFraction >= 0.9 ? .attention : nil
            ) { SeriesSparkline(metric: .diskWrite, tint: .indigo) }))
        }
        if let network = snapshot.network {
            tiles.append(tile(.network, MetricTile(
                title: tr("Network"), symbol: "arrow.up.arrow.down",
                value: formatter.rate(network.downloadRate ?? 0),
                caption: tr("Upload %@", formatter.rate(network.uploadRate ?? 0))
            ) { SeriesSparkline(metric: .networkDownload, tint: .cyan) }))
        }
        return tiles
    }

    private static func tile(_ destination: Destination, _ view: some View, id: String? = nil) -> Tile {
        Tile(id: id ?? destination.rawValue, destination: destination, view: AnyView(view))
    }

    static func batterySymbol(_ battery: BatterySnapshot) -> String {
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
