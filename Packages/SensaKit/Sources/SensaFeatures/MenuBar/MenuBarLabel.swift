import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Compact content of the status item. Kept tiny: it renders on every update.
public struct MenuBarLabel: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        let items = settings.enabledMenuBarItems
        let formatter = settings.formatter
        HStack(spacing: 6) {
            if items.isEmpty {
                Image(systemName: "gauge.with.dots.needle.67percent")
            }
            ForEach(items) { item in
                if let value = MenuBarValues.value(for: item.indicator, snapshot: store.snapshot, formatter: formatter) {
                    HStack(spacing: 2) {
                        Image(systemName: MenuBarValues.symbol(for: item.indicator))
                            .font(.system(size: 11, weight: .medium))
                        if item.showsSparkline, let metric = MenuBarValues.metric(for: item.indicator) {
                            SparklineChart(points: store.series(for: metric).points().suffix(30).map { $0 }, tint: .primary)
                                .frame(width: 26, height: 14)
                        }
                        Text(value)
                            .font(.system(size: 12, weight: .medium).monospacedDigit())
                    }
                }
            }
        }
        .fixedSize()
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }
}

public extension MenuBarLabel {
    /// Everything the label displays, as a comparable key. The status item re-renders its image
    /// only when this changes (or when a sparkline is shown), avoiding redundant work.
    @MainActor
    static func renderKey(store: MetricsStore, settings: AppSettings) -> String? {
        let items = settings.enabledMenuBarItems
        guard !items.contains(where: \.showsSparkline) else { return nil }
        let formatter = settings.formatter
        return items.map { "\($0.indicator.rawValue)=\(MenuBarValues.value(for: $0.indicator, snapshot: store.snapshot, formatter: formatter) ?? "-")" }
            .joined(separator: "|")
    }
}

/// Values shown for each indicator, shared by the status item and its settings preview.
enum MenuBarValues {
    static func value(for indicator: MenuBarIndicator, snapshot: SystemSnapshot, formatter: MetricFormatter) -> String? {
        switch indicator {
        case .cpuUsage: snapshot.cpu.map { formatter.percent($0.totalUsage) }
        case .cpuTemperature: snapshot.sensors?.cpuTemperature.map { formatter.temperature($0) }
        case .gpuUsage: snapshot.gpu.map { formatter.percent($0.deviceUtilization) }
        case .memoryPressure: snapshot.memory.map { $0.pressureFraction.map { formatter.percent($0) } ?? formatter.bytes($0.used) }
        case .battery: snapshot.battery.map { formatter.percent($0.charge) }
        case .power: snapshot.sensors?.systemPower.map { formatter.watts($0, fractionDigits: 0) }
        case .fans: snapshot.sensors?.fans.map(\.currentRPM).max().map { formatter.rpm($0) }
        case .network: snapshot.network.map { "↓\(formatter.rate($0.downloadRate ?? 0))" }
        }
    }

    static func symbol(for indicator: MenuBarIndicator) -> String {
        switch indicator {
        case .cpuUsage: "cpu"
        case .cpuTemperature: "thermometer.medium"
        case .gpuUsage: "square.stack.3d.up"
        case .memoryPressure: "memorychip"
        case .battery: "battery.75percent"
        case .power: "bolt"
        case .fans: "fan"
        case .network: "network"
        }
    }

    static func metric(for indicator: MenuBarIndicator) -> MetricID? {
        switch indicator {
        case .cpuUsage: .cpuUsage
        case .cpuTemperature: .cpuTemperature
        case .gpuUsage: .gpuUsage
        case .memoryPressure: .memoryPressure
        case .battery: .batteryCharge
        case .power: .systemPower
        case .fans: .fanSpeed(0)
        case .network: .networkDownload
        }
    }

    static func title(for indicator: MenuBarIndicator) -> String {
        switch indicator {
        case .cpuUsage: tr("CPU usage")
        case .cpuTemperature: tr("CPU temperature")
        case .gpuUsage: tr("GPU usage")
        case .memoryPressure: tr("Memory pressure")
        case .battery: tr("Battery")
        case .power: tr("Power")
        case .fans: tr("Fans")
        case .network: tr("Network")
        }
    }
}
