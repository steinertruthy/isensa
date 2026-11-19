import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct ThermalsScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let thermal = store.snapshot.thermal
        let sensors = store.snapshot.sensors
        ScreenContainer(title: tr("Temperatures"), summary: thermal.map { Descriptions.thermal($0.level) } ?? tr("Reading sensors…")) {
            if let thermal {
                Card(tr("Thermal state"), symbol: "thermometer.sun", accessory: {
                    StatusBadge(level: Descriptions.thermalLevel(thermal.level), text: Descriptions.thermal(thermal.level))
                }) {
                    Text(tr("This is macOS' own assessment. When it rises to “serious”, macOS reduces performance to keep the Mac within safe temperatures."))
                        .font(Typography.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            if let sensors {
                HStack(spacing: Spacing.large) {
                    if let cpu = sensors.cpuTemperature { temperatureTile(tr("CPU"), cpu, metric: .cpuTemperature, formatter: formatter) }
                    if let gpu = sensors.gpuTemperature { temperatureTile(tr("GPU"), gpu, metric: .gpuTemperature, formatter: formatter) }
                    if let power = sensors.systemPower {
                        MetricTile(title: tr("Power"), symbol: "bolt", value: formatter.watts(power), caption: tr("Total system power draw")) {
                            SeriesSparkline(metric: .systemPower, tint: .yellow)
                        }
                    }
                }
                if sensors.cpuTemperature == nil {
                    CapabilityNotice(
                        symbol: "questionmark.circle",
                        title: tr("CPU temperature not identified on this model"),
                        message: tr("Sensa only names sensors after validating them on a Mac model. All raw sensors are still available in Sensors.")
                    )
                }
                SeriesChartCard(
                    title: tr("Temperature history"), symbol: "chart.xyaxis.line",
                    lines: [.init(metric: .cpuTemperature, label: tr("CPU"), color: .orange), .init(metric: .gpuTemperature, label: tr("GPU"), color: .purple)],
                    transform: { settings.temperatureUnit == .celsius ? $0 : $0 * 9 / 5 + 32 },
                    format: { formatter.number($0) + "°" }
                )
                ProvenanceTag(tr("Read through undocumented interfaces (SMC, HID). Experimental."), symbol: "flask")
            } else if store.capabilities.isUsable(.temperatureSensors) || store.capabilities[.temperatureSensors] == nil {
                WaitingView()
            }
            TechnicalDetails {
                if let pressure = thermal?.pressure { InfoRow(tr("Thermal pressure"), value: "\(pressure)") }
                InfoRow(tr("Sensors read"), value: "\(sensors?.sensors.count ?? 0)")
                InfoRow(tr("Source"), value: "ProcessInfo.thermalState · SMC · IOHIDEventSystem")
            }
        }
    }

    private func temperatureTile(_ title: String, _ value: Double, metric: MetricID, formatter: MetricFormatter) -> some View {
        MetricTile(title: title, symbol: "thermometer.medium", value: formatter.temperature(value), caption: tr("Average of identified sensors")) {
            SeriesSparkline(metric: metric, tint: .orange)
        }
    }
}
