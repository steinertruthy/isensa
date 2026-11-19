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
        ScreenContainer(title: tr("CPU"), summary: cpu.map { Descriptions.cpuLoad($0.totalUsage) } ?? tr("Reading sensors…"), symbol: "cpu", hue: .cpu) {
            if let cpu {
                HeroInstrument(stats: stats(cpu, formatter: formatter)) {
                    GaugeInstrument(fraction: cpu.totalUsage, hue: .cpu, value: formatter.percent(cpu.totalUsage), caption: tr("in use"))
                }
                SeriesChartCard(
                    title: tr("Usage history"),
                    lines: [
                        .init(metric: .cpuUsage, label: tr("Total"), color: Hue.cpu.color),
                        .init(metric: .cpuSystemUsage, label: tr("System"), color: .secondary)
                    ],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                if let clusters = store.snapshot.performance?.clusters.filter({ $0.kind != .gpu }), !clusters.isEmpty {
                    ClusterActivityCard(clusters: clusters, hue: .cpu, formatter: formatter)
                }
                CoreGrid(cores: cpu.cores, formatter: formatter)
                if let processes = store.snapshot.processes {
                    ProcessListCard(
                        title: tr("Using the most CPU"), processes: processes.topByCPU, ranking: .cpu,
                        inaccessibleCount: processes.inaccessibleCount, formatter: formatter
                    )
                }
                TechnicalDetails { details(cpu, formatter: formatter) }
            } else {
                WaitingView()
            }
        }
    }

    private func stats(_ cpu: CPUSnapshot, formatter: MetricFormatter) -> [Stat] {
        var stats = [Stat(tr("User"), value: formatter.percent(cpu.userUsage)), Stat(tr("System"), value: formatter.percent(cpu.systemUsage))]
        if let performance = cpu.averageUsage(of: .performance) { stats.append(Stat(tr("Performance cores"), value: formatter.percent(performance))) }
        if let efficiency = cpu.averageUsage(of: .efficiency) { stats.append(Stat(tr("Efficiency cores"), value: formatter.percent(efficiency))) }
        if let temperature = store.snapshot.sensors?.cpuTemperature {
            stats.append(Stat(tr("Temperature"), value: formatter.temperature(temperature), note: tr("Average of the CPU cluster sensors")))
        }
        if let watts = store.snapshot.power?.rails[.cpu] {
            stats.append(Stat(tr("CPU power"), value: formatter.watts(watts, fractionDigits: 2)))
        }
        return stats
    }

    @ViewBuilder
    private func details(_ cpu: CPUSnapshot, formatter: MetricFormatter) -> some View {
        let profile = store.profile
        InfoRow(tr("Processor"), value: profile.chipName)
        InfoRow(tr("Architecture"), value: profile.architecture.rawValue)
        InfoRow(tr("Cores"), value: "\(profile.cpu.physicalCores)")
        if let performance = profile.cpu.performanceCores, let efficiency = profile.cpu.efficiencyCores {
            InfoRow(tr("Performance / efficiency"), value: "\(performance) / \(efficiency)")
        }
        if cpu.loadAverage.count == 3 {
            InfoRow(
                tr("Load average (1, 5, 15 min)"),
                value: cpu.loadAverage.map { formatter.number($0, fractionDigits: 2) }.joined(separator: "   "),
                help: tr("Average number of tasks running or waiting for the CPU.")
            )
        }
        InfoRow(tr("Source"), value: "host_processor_info, IOReport")
    }
}

private struct CoreGrid: View {
    let cores: [CPUSnapshot.Core]
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Cores")) {
            ForEach([CoreKind.performance, .efficiency, .uniform], id: \.self) { kind in
                let group = cores.filter { $0.kind == kind }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        if kind != .uniform {
                            Text(kind == .performance ? tr("Performance cores") : tr("Efficiency cores"))
                                .font(Typography.caption).foregroundStyle(.secondary)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: Spacing.small)], spacing: Spacing.small) {
                            ForEach(group) { core in
                                CoreBar(usage: core.usage, tint: kind == .efficiency ? Hue.cpu.color.opacity(0.6) : Hue.cpu.color)
                                    .help(tr("Core %@: %@", "\(core.id)", formatter.percent(core.usage)))
                                    .accessibilityLabel(tr("Core %@: %@", "\(core.id)", formatter.percent(core.usage)))
                            }
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

    var body: some View {
        VStack(spacing: Spacing.xSmall) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Color.primary.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(tint.gradient)
                        .frame(height: max(geometry.size.height * usage, 2))
                }
            }
            .frame(height: 52)
            Text("\(Int((usage * 100).rounded()))").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .sensaAnimation(Motion.update, value: usage)
    }
}
