import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct CPUScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let cpu = store.snapshot.cpu
        ScreenContainer(title: tr("CPU"), summary: cpu.map { Descriptions.cpuLoad($0.totalUsage) } ?? tr("Reading sensors…")) {
            if let cpu {
                HStack(alignment: .top, spacing: Spacing.large) {
                    Card {
                        HStack(spacing: Spacing.xLarge) {
                            RingGauge(value: cpu.totalUsage, tint: .blue, lineWidth: 12) {
                                VStack(spacing: 0) {
                                    Text(formatter.percent(cpu.totalUsage)).font(Typography.metric).contentTransition(.numericText())
                                    Text(tr("in use")).font(Typography.caption).foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 130, height: 130)
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                InfoRow(tr("User"), value: formatter.percent(cpu.userUsage))
                                InfoRow(tr("System"), value: formatter.percent(cpu.systemUsage))
                                if let performance = cpu.averageUsage(of: .performance) {
                                    InfoRow(tr("Performance cores"), value: formatter.percent(performance))
                                }
                                if let efficiency = cpu.averageUsage(of: .efficiency) {
                                    InfoRow(tr("Efficiency cores"), value: formatter.percent(efficiency))
                                }
                            }
                        }
                    }
                    if let temperature = store.snapshot.sensors?.cpuTemperature {
                        Card(tr("Temperature"), symbol: "thermometer.medium") {
                            Text(formatter.temperature(temperature)).font(Typography.metric).contentTransition(.numericText())
                            Text(tr("Average of the CPU cluster sensors")).font(Typography.caption).foregroundStyle(.secondary)
                            ProvenanceTag(tr("Derived"))
                        }
                        .frame(maxWidth: 260)
                    }
                }
                SeriesChartCard(
                    title: tr("Usage history"), symbol: "chart.xyaxis.line",
                    lines: [.init(metric: .cpuUsage, label: tr("Total"), color: .blue), .init(metric: .cpuSystemUsage, label: tr("System"), color: .red)],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                CoreGrid(cores: cpu.cores, formatter: formatter)
                TechnicalDetails {
                    let profile = store.profile
                    InfoRow(tr("Processor"), value: profile.chipName)
                    InfoRow(tr("Architecture"), value: profile.architecture.rawValue)
                    InfoRow(tr("Cores"), value: "\(profile.cpu.physicalCores)")
                    if let p = profile.cpu.performanceCores, let e = profile.cpu.efficiencyCores {
                        InfoRow(tr("Performance / efficiency"), value: "\(p) / \(e)")
                    }
                    if cpu.loadAverage.count == 3 {
                        InfoRow(
                            tr("Load average (1, 5, 15 min)"),
                            value: cpu.loadAverage.map { formatter.number($0, fractionDigits: 2) }.joined(separator: " · "),
                            help: tr("Average number of tasks running or waiting for the CPU.")
                        )
                    }
                    InfoRow(tr("Source"), value: "host_processor_info")
                }
            } else {
                WaitingView()
            }
        }
    }
}

private struct CoreGrid: View {
    let cores: [CPUSnapshot.Core]
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Cores"), symbol: "square.grid.3x3") {
            ForEach([CoreKind.performance, .efficiency, .uniform], id: \.self) { kind in
                let group = cores.filter { $0.kind == kind }
                if !group.isEmpty {
                    if kind != .uniform {
                        Text(kind == .performance ? tr("Performance cores") : tr("Efficiency cores"))
                            .font(Typography.caption).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: Spacing.small)], spacing: Spacing.small) {
                        ForEach(group) { core in
                            CoreBar(usage: core.usage, tint: kind == .efficiency ? .teal : .blue)
                                .help(tr("Core %@: %@", "\(core.id)", formatter.percent(core.usage)))
                                .accessibilityLabel(tr("Core %@: %@", "\(core.id)", formatter.percent(core.usage)))
                        }
                    }
                }
            }
        }
    }
}

private struct CoreBar: View {
    let usage: Double
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.xSmall) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous).fill(tint.opacity(0.12))
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.gradient)
                        .frame(height: max(geometry.size.height * usage, 3))
                }
            }
            .frame(height: 56)
            Text("\(Int((usage * 100).rounded()))").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: usage)
    }
}
