import iSensaCore
import iSensaDesign
import iSensaMonitoring
import SwiftUI

struct ThermalsScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let thermal = store.snapshot.thermal
        let sensors = store.snapshot.sensors
        let ssd = Self.ssdSensor(sensors)
        ScreenContainer(
            title: tr("Temperatures"), summary: thermal.map { Descriptions.thermal($0.level) } ?? tr("Reading sensors…"),
            symbol: "thermometer.medium", hue: .thermal
        ) {
            if let sensors, sensors.cpuTemperature != nil || sensors.gpuTemperature != nil {
                HeroInstrument(stats: stats(sensors, formatter: formatter)) {
                    if let cpu = sensors.cpuTemperature {
                        GaugeInstrument(
                            fraction: min(max((cpu - 20) / 90, 0), 1), hue: .thermal, value: formatter.temperature(cpu), caption: tr("CPU average")
                        )
                    }
                }
            } else if sensors != nil {
                CapabilityNotice(
                    symbol: "questionmark.circle",
                    title: tr("CPU temperature not identified on this model"),
                    message: tr("iSensa only names sensors after validating them on a Mac model. All raw sensors are still available in Sensors.")
                )
            }
            if let thermal {
                Card(tr("Thermal state"), accessory: {
                    StatusBadge(level: Descriptions.thermalLevel(thermal.level), text: Descriptions.thermal(thermal.level))
                }) {
                    Text(tr("This is macOS' own assessment. When it rises to “serious”, macOS reduces performance to keep the Mac within safe temperatures."))
                        .font(Typography.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            if sensors != nil {
                SeriesChartCard(
                    title: tr("Temperature history"),
                    lines: [
                        .init(metric: .cpuTemperature, label: tr("CPU"), color: Hue.cpu.color),
                        .init(metric: .gpuTemperature, label: tr("GPU"), color: Hue.gpu.color)
                    ] + (ssd.map { [.init(metric: .sensor($0.id), label: "SSD", color: Hue.storage.color)] } ?? []),
                    transform: { settings.temperatureUnit == .celsius ? $0 : $0 * 9 / 5 + 32 },
                    format: { formatter.number($0) + "°" }
                )
            }
            if let power = store.snapshot.power, !power.rails.isEmpty {
                PowerRailsCard(power: power, systemPower: sensors?.systemPower, formatter: formatter)
            }
            if sensors == nil, store.capabilities.isUsable(.temperatureSensors) || store.capabilities[.temperatureSensors] == nil {
                WaitingView()
            }
            ProvenanceTag(tr("Read through undocumented interfaces (SMC, HID). Experimental."), symbol: "flask")
            TechnicalDetails {
                if let pressure = thermal?.pressure { InfoRow(tr("Thermal pressure"), value: "\(pressure)") }
                InfoRow(tr("Sensors read"), value: "\(sensors?.sensors.count ?? 0)")
                InfoRow(tr("Source"), value: "ProcessInfo.thermalState, SMC, IOHIDEventSystem")
            }
        }
    }

    private func stats(_ sensors: SensorSnapshot, formatter: MetricFormatter) -> [Stat] {
        var stats: [Stat] = []
        if let hottest = sensors.cpuHottestTemperature {
            stats.append(Stat(tr("Hottest core"), value: formatter.temperature(hottest), note: tr("Fan curves follow this reading")))
        }
        if let gpu = sensors.gpuTemperature { stats.append(Stat(tr("GPU"), value: formatter.temperature(gpu), note: tr("Average of the GPU sensors"))) }
        if let power = sensors.systemPower { stats.append(Stat(tr("Power"), value: formatter.watts(power), note: tr("Total system power draw"))) }
        if let ssd = Self.ssdSensor(sensors) {
            stats.append(Stat("SSD", value: formatter.temperature(ssd.value), note: tr("Measured inside the drive")))
        } else if let ssd = store.snapshot.storage?.ssdHealth?.temperature {
            stats.append(Stat("SSD", value: formatter.temperature(ssd), note: tr("Reported by the drive (SMART)")))
        }
        return stats
    }

    /// The SSD's own temperature sensor (the NAND sensor), read with the other sensors every few seconds.
    static func ssdSensor(_ sensors: SensorSnapshot?) -> SensorReading? {
        sensors?.sensors.first { $0.sensor.group == .storage && $0.sensor.kind == .temperature }
    }
}
