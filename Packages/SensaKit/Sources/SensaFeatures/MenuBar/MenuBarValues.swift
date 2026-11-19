import SensaCore
import SensaMonitoring

/// Value, symbol, series and title for each menu bar indicator. Shared by the status item,
/// the popover and the settings list, so every place shows the same thing.
enum MenuBarValues {
    static func value(for indicator: MenuBarIndicator, snapshot: SystemSnapshot, formatter: MetricFormatter, decimals: Int = 0) -> String? {
        switch indicator {
        case .cpuUsage: snapshot.cpu.map { formatter.percent($0.totalUsage, fractionDigits: decimals) }
        case .cpuTemperature: snapshot.sensors?.cpuTemperature.map { formatter.temperature($0, fractionDigits: decimals) }
        case .gpuUsage: snapshot.gpu.map { formatter.percent($0.deviceUtilization, fractionDigits: decimals) }
        case .gpuTemperature: snapshot.sensors?.gpuTemperature.map { formatter.temperature($0, fractionDigits: decimals) }
        case .memoryUsed: snapshot.memory.map { formatter.bytes($0.used) }
        case .memoryPressure: snapshot.memory?.pressureFraction.map { formatter.percent($0, fractionDigits: decimals) }
        case .battery: snapshot.battery.map { formatter.percent($0.charge) }
        case .power: snapshot.sensors?.systemPower.map { formatter.watts($0, fractionDigits: decimals) }
        case .fans: snapshot.sensors?.fans.map(\.currentRPM).max().map { formatter.rpm($0) }
        case .network: snapshot.network.map { "↓\(formatter.rate($0.downloadRate ?? 0)) ↑\(formatter.rate($0.uploadRate ?? 0))" }
        }
    }

    static func symbol(for indicator: MenuBarIndicator, snapshot: SystemSnapshot? = nil) -> String {
        switch indicator {
        case .cpuUsage: "cpu"
        case .cpuTemperature, .gpuTemperature: "thermometer.medium"
        case .gpuUsage: "square.stack.3d.up"
        case .memoryUsed, .memoryPressure: "memorychip"
        case .battery: snapshot?.battery.map(DashboardTiles.batterySymbol) ?? "battery.75percent"
        case .power: "bolt"
        case .fans: "fan"
        case .network: "arrow.up.arrow.down"
        }
    }

    static func metric(for indicator: MenuBarIndicator) -> MetricID {
        switch indicator {
        case .cpuUsage: .cpuUsage
        case .cpuTemperature: .cpuTemperature
        case .gpuUsage: .gpuUsage
        case .gpuTemperature: .gpuTemperature
        case .memoryUsed: .memoryUsed
        case .memoryPressure: .memoryPressure
        case .battery: .batteryCharge
        case .power: .systemPower
        case .fans: .fanSpeed(0)
        case .network: .networkDownload
        }
    }

    /// Fixed scale for sparklines whose metric has a natural range; `nil` = scale to the data.
    static func range(for indicator: MenuBarIndicator) -> ClosedRange<Double>? {
        switch indicator {
        case .cpuUsage, .gpuUsage, .memoryPressure, .battery: 0...1
        default: nil
        }
    }

    static func title(for indicator: MenuBarIndicator) -> String {
        switch indicator {
        case .cpuUsage: tr("CPU usage")
        case .cpuTemperature: tr("CPU temperature")
        case .gpuUsage: tr("GPU usage")
        case .gpuTemperature: tr("GPU temperature")
        case .memoryUsed: tr("Memory used")
        case .memoryPressure: tr("Memory pressure")
        case .battery: tr("Battery")
        case .power: tr("Power")
        case .fans: tr("Fans")
        case .network: tr("Network")
        }
    }
}
