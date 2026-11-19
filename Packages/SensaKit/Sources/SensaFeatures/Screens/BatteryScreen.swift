import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct BatteryScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let battery = store.snapshot.battery
        ScreenContainer(
            title: tr("Battery"), summary: battery.map { DashboardModel.batteryCaption($0, formatter: formatter) } ?? tr("Reading sensors…"),
            symbol: battery.map(DashboardModel.batterySymbol) ?? "battery.75percent", hue: .battery
        ) {
            if let battery {
                HeroInstrument(stats: stats(battery, formatter: formatter)) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        BatteryGlyph(charge: battery.charge, isCharging: battery.state == .charging, tint: tint(battery))
                            .frame(width: 150)
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                            MetricText(formatter.percent(battery.charge), size: .hero, rolls: true)
                            Text(Descriptions.chargeState(battery)).font(Typography.callout).foregroundStyle(.secondary)
                        }
                    }
                }
                SeriesChartCard(
                    title: tr("Charge"),
                    lines: [.init(metric: .batteryCharge, label: tr("Charge"), color: Hue.battery.color)],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                Text(Copy.chargeLimitNote).font(Typography.caption).foregroundStyle(.secondary)
                TechnicalDetails { details(battery, formatter: formatter) }
            } else {
                WaitingView()
            }
        }
    }

    private func stats(_ battery: BatterySnapshot, formatter: MetricFormatter) -> [Stat] {
        var stats: [Stat] = []
        if let health = battery.health {
            stats.append(Stat(tr("Health"), value: formatter.percent(min(health, 1)), note: tr("Maximum capacity relative to when it was new")))
        }
        if let cycles = battery.cycleCount { stats.append(Stat(tr("Charge cycles"), value: formatter.integer(cycles))) }
        if let power = battery.power {
            stats.append(Stat(
                tr("Power flow"), value: formatter.watts(abs(power)),
                note: power >= 0 ? tr("Flowing into the battery") : tr("Being drawn from the battery")
            ))
        }
        if let condition = battery.systemCondition {
            stats.append(Stat(tr("Condition"), value: ["Good", "Normal"].contains(condition) ? tr("Normal") : condition, note: tr("Reported by macOS")))
        }
        if let watts = battery.adapter?.watts { stats.append(Stat(tr("Power adapter"), value: "\(watts) W")) }
        return stats
    }

    private func tint(_ battery: BatterySnapshot) -> Color {
        if battery.state == .discharging, battery.charge < 0.15 { return .red }
        if battery.state == .discharging, battery.charge < 0.3 { return .orange }
        return Hue.battery.color
    }

    @ViewBuilder
    private func details(_ battery: BatterySnapshot, formatter: MetricFormatter) -> some View {
        if let design = battery.designCapacity { InfoRow(tr("Design capacity"), value: formatter.milliampereHours(design)) }
        if let nominal = battery.nominalCapacity { InfoRow(tr("Full charge capacity"), value: formatter.milliampereHours(nominal)) }
        if let raw = battery.rawMaxCapacity { InfoRow(tr("Raw maximum capacity"), value: formatter.milliampereHours(raw)) }
        if let remaining = battery.remainingCapacity { InfoRow(tr("Remaining charge"), value: formatter.milliampereHours(remaining)) }
        if let voltage = battery.voltage { InfoRow(tr("Voltage"), value: formatter.volts(voltage)) }
        if let amperage = battery.amperage {
            InfoRow(tr("Current"), value: formatter.amperes(amperage), help: tr("Positive while charging, negative while discharging."))
        }
        if let temperature = battery.temperature { InfoRow(tr("Temperature"), value: formatter.temperature(temperature, fractionDigits: 1)) }
        if let adapter = battery.adapter, let name = adapter.name { InfoRow(tr("Adapter"), value: name) }
        InfoRow(tr("Source"), value: "IOPowerSources, AppleSmartBattery")
    }
}
