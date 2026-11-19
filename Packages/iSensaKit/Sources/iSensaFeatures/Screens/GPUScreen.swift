import iSensaCore
import iSensaDesign
import iSensaMonitoring
import SwiftUI

struct GPUScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let gpu = store.snapshot.gpu
        ScreenContainer(
            title: tr("GPU"), summary: gpu.map { Descriptions.cpuLoad($0.deviceUtilization) } ?? tr("Reading sensors…"),
            symbol: "square.stack.3d.up", hue: .gpu
        ) {
            if let gpu {
                HeroInstrument(stats: stats(gpu, formatter: formatter)) {
                    GaugeInstrument(fraction: gpu.deviceUtilization, hue: .gpu, value: formatter.percent(gpu.deviceUtilization), caption: tr("in use"))
                }
                SeriesChartCard(
                    title: tr("Usage history"),
                    lines: [.init(metric: .gpuUsage, label: tr("GPU"), color: Hue.gpu.color)],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                if let cluster = store.snapshot.performance?.cluster(.gpu) {
                    ClusterActivityCard(clusters: [cluster], hue: .gpu, formatter: formatter)
                }
                TechnicalDetails {
                    InfoRow(tr("Model"), value: gpu.name)
                    if let cores = gpu.coreCount { InfoRow(tr("GPU cores"), value: "\(cores)") }
                    InfoRow(tr("Source"), value: "IOAccelerator, IOReport")
                }
            } else {
                WaitingView()
            }
        }
    }

    private func stats(_ gpu: GPUSnapshot, formatter: MetricFormatter) -> [Stat] {
        var stats: [Stat] = []
        if let renderer = gpu.rendererUtilization { stats.append(Stat(tr("Rendering"), value: formatter.percent(renderer))) }
        if let tiler = gpu.tilerUtilization { stats.append(Stat(tr("Geometry (tiler)"), value: formatter.percent(tiler))) }
        if let memory = gpu.memoryInUse {
            stats.append(Stat(tr("Memory in use"), value: formatter.bytes(memory), note: tr("Shared with the CPU")))
        }
        if let temperature = store.snapshot.sensors?.gpuTemperature {
            stats.append(Stat(tr("Temperature"), value: formatter.temperature(temperature), note: tr("Average of the GPU sensors")))
        }
        if let watts = store.snapshot.power?.rails[.gpu] {
            stats.append(Stat(tr("GPU power"), value: formatter.watts(watts, fractionDigits: 2)))
        }
        return stats
    }
}
