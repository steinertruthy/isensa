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
        ScreenContainer(title: tr("Battery"), summary: battery.map { DashboardTiles.batteryCaption($0, formatter: formatter) } ?? tr("Reading sensors…")) {
            if let battery {
                Card {
                    HStack(spacing: Spacing.xxLarge) {
                        BatteryGlyph(charge: battery.charge, isCharging: battery.state == .charging, tint: tint(battery))
                            .frame(width: 180)
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(formatter.percent(battery.charge)).font(Typography.metricLarge).contentTransition(.numericText())
                            Label(Descriptions.chargeState(battery), systemImage: DashboardTiles.batterySymbol(battery))
                                .font(Typography.headline)
                            if let adapter = battery.adapter, let watts = adapter.watts {
                                Text(tr("Power adapter: %@ W", "\(watts)")).font(Typography.callout).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
                HStack(alignment: .top, spacing: Spacing.large) {
                    HealthCard(battery: battery, formatter: formatter)
                    if let power = battery.power {
                        Card(tr("Power flow"), symbol: "bolt", accessory: { ProvenanceTag(tr("Derived")) }) {
                            Text(formatter.watts(abs(power))).font(Typography.metric).contentTransition(.numericText())
                            Text(power >= 0 ? tr("Flowing into the battery") : tr("Being drawn from the battery"))
                                .font(Typography.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                SeriesChartCard(
                    title: tr("Charge"), symbol: "chart.xyaxis.line",
                    lines: [.init(metric: .batteryCharge, label: tr("Charge"), color: .green)],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                Text(Copy.chargeLimitNote)
                    .font(Typography.caption).foregroundStyle(.secondary)
                TechnicalDetails { details(battery, formatter: formatter) }
            } else {
                WaitingView()
            }
        }
    }

    private func tint(_ battery: BatterySnapshot) -> Color {
        if battery.state == .discharging, battery.charge < 0.15 { return .red }
        if battery.state == .discharging, battery.charge < 0.3 { return .orange }
        return .green
    }

    @ViewBuilder
    private func details(_ battery: BatterySnapshot, formatter: MetricFormatter) -> some View {
        if let design = battery.designCapacity { InfoRow(tr("Design capacity"), value: formatter.milliampereHours(design)) }
        if let nominal = battery.nominalCapacity { InfoRow(tr("Full charge capacity"), value: formatter.milliampereHours(nominal)) }
        if let raw = battery.rawMaxCapacity { InfoRow(tr("Raw maximum capacity"), value: formatter.milliampereHours(raw)) }
        if let remaining = battery.remainingCapacity { InfoRow(tr("Remaining charge"), value: formatter.milliampereHours(remaining)) }
        if let voltage = battery.voltage { InfoRow(tr("Voltage"), value: formatter.volts(voltage)) }
        if let amperage = battery.amperage { InfoRow(
            tr("Current"),
            value: formatter.amperes(amperage),
            help: tr("Positive while charging, negative while discharging.")
        ) }
        if let temperature = battery.temperature { InfoRow(tr("Temperature"), value: formatter.temperature(temperature, fractionDigits: 1)) }
        if let adapter = battery.adapter {
            InfoRow(tr("Adapter"), value: [adapter.name, adapter.watts.map { "\($0) W" }].compactMap { $0 }.joined(separator: " · "))
        }
        InfoRow(tr("Source"), value: "IOPowerSources · AppleSmartBattery")
    }
}

private struct HealthCard: View {
    let battery: BatterySnapshot
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Health"), symbol: "heart.text.square", accessory: {
            if let condition = battery.systemCondition {
                StatusBadge(level: ["Good", "Normal"].contains(condition) ? .normal : .attention, text: conditionText(condition))
            }
        }) {
            if let health = battery.health {
                Text(formatter.percent(min(health, 1))).font(Typography.metric)
                Text(tr("Maximum capacity relative to when it was new")).font(Typography.caption).foregroundStyle(.secondary)
            }
            if let cycles = battery.cycleCount {
                InfoRow(
                    tr("Charge cycles"),
                    value: formatter.integer(cycles),
                    help: tr("One cycle equals using 100% of the battery's capacity, possibly across several charges.")
                )
            }
        }
    }

    private func conditionText(_ condition: String) -> String {
        switch condition {
        case "Good", "Normal": tr("Normal")
        default: condition
        }
    }
}
