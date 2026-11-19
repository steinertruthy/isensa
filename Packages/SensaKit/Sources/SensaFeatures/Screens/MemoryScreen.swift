import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct MemoryScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let memory = store.snapshot.memory
        ScreenContainer(title: tr("Memory"), summary: summary(memory, formatter: formatter), symbol: "memorychip", hue: .memory) {
            if let memory {
                HeroInstrument(stats: [
                    Stat(tr("Used"), value: formatter.bytes(memory.used)),
                    Stat(tr("Installed"), value: formatter.bytes(memory.total)),
                    Stat(tr("Cached files"), value: formatter.bytes(memory.cached), note: tr("Freed instantly when needed")),
                    Stat(tr("Swap used"), value: formatter.bytes(memory.swapUsed))
                ]) {
                    GaugeInstrument(
                        fraction: memory.pressureFraction ?? memory.usedFraction, hue: .memory,
                        value: formatter.percent(memory.pressureFraction ?? memory.usedFraction), caption: tr("pressure")
                    )
                }
                Card(tr("Memory pressure"), accessory: {
                    StatusBadge(level: Descriptions.memoryLevel(memory.pressure), text: Descriptions.memoryPressure(memory.pressure))
                }) {
                    Text(Copy.memoryPressureExplanation)
                        .font(Typography.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    SeriesSparkline(metric: .memoryPressure, range: 0...1, tint: Hue.memory.color).frame(height: 56)
                }
                Card(tr("Usage")) {
                    SegmentedMeter(segments: [
                        .init(id: "app", label: tr("Apps"), value: Double(memory.app), color: Hue.memory.color, detail: formatter.bytes(memory.app)),
                        .init(
                            id: "wired",
                            label: tr("Wired"),
                            value: Double(memory.wired),
                            color: Hue.memory.color.opacity(0.65),
                            detail: formatter.bytes(memory.wired)
                        ),
                        .init(
                            id: "compressed", label: tr("Compressed"), value: Double(memory.compressed),
                            color: Hue.memory.color.opacity(0.4), detail: formatter.bytes(memory.compressed)
                        ),
                        .init(
                            id: "cached",
                            label: tr("Cached files"),
                            value: Double(memory.cached),
                            color: .secondary.opacity(0.35),
                            detail: formatter.bytes(memory.cached)
                        )
                    ], total: Double(memory.total))
                }
                SeriesChartCard(
                    title: tr("Memory used"),
                    lines: [.init(metric: .memoryUsed, label: tr("Used"), color: Hue.memory.color)],
                    range: 0...Double(memory.total) / 1_073_741_824, transform: { $0 / 1_073_741_824 },
                    format: { "\(formatter.number($0, fractionDigits: 0)) GB" }
                )
                if let processes = store.snapshot.processes {
                    ProcessListCard(
                        title: tr("Using the most memory"), processes: processes.topByMemory, ranking: .memory,
                        inaccessibleCount: processes.inaccessibleCount, formatter: formatter
                    )
                }
                TechnicalDetails {
                    InfoRow(tr("Apps"), value: formatter.bytes(memory.app))
                    InfoRow(tr("Wired"), value: formatter.bytes(memory.wired), help: tr("Memory the system must keep in RAM."))
                    InfoRow(tr("Compressed"), value: formatter.bytes(memory.compressed))
                    InfoRow(tr("Free"), value: formatter.bytes(memory.free))
                    InfoRow(tr("Swap"), value: "\(formatter.bytes(memory.swapUsed)) / \(formatter.bytes(memory.swapTotal))")
                    if store.profile.chipFamily.isAppleSilicon {
                        InfoRow(tr("Architecture"), value: tr("Unified memory (shared by CPU and GPU)"))
                    }
                    InfoRow(tr("Source"), value: "host_statistics64, kern.memorystatus")
                }
            } else {
                WaitingView()
            }
        }
    }

    private func summary(_ memory: MemorySnapshot?, formatter: MetricFormatter) -> String {
        guard let memory else { return tr("Reading sensors…") }
        let pressure = memory.pressure == .normal
            ? tr("Your Mac is managing resources normally.")
            : Descriptions.memoryPressure(memory.pressure) + "."
        return tr("You are using %@ of memory.", formatter.bytes(memory.used)) + " " + pressure
    }
}
