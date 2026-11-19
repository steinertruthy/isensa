import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct GPUScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let gpu = store.snapshot.gpu
        ScreenContainer(title: tr("GPU"), summary: gpu.map { Descriptions.cpuLoad($0.deviceUtilization) } ?? tr("Reading sensors…")) {
            if let gpu {
                HStack(alignment: .top, spacing: Spacing.large) {
                    Card {
                        HStack(spacing: Spacing.xLarge) {
                            RingGauge(value: gpu.deviceUtilization, tint: .purple, lineWidth: 12) {
                                VStack(spacing: 0) {
                                    Text(formatter.percent(gpu.deviceUtilization)).font(Typography.metric).contentTransition(.numericText())
                                    Text(tr("in use")).font(Typography.caption).foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 130, height: 130)
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                if let renderer = gpu.rendererUtilization { InfoRow(tr("Rendering"), value: formatter.percent(renderer)) }
                                if let tiler = gpu.tilerUtilization { InfoRow(tr("Geometry (tiler)"), value: formatter.percent(tiler)) }
                                if let memory = gpu.memoryInUse {
                                    InfoRow(
                                        tr("Memory in use"),
                                        value: formatter.bytes(memory),
                                        help: tr("Unified memory currently used by the GPU. On Apple silicon the CPU and GPU share the same memory.")
                                    )
                                }
                            }
                        }
                    }
                    if let temperature = store.snapshot.sensors?.gpuTemperature {
                        Card(tr("Temperature"), symbol: "thermometer.medium") {
                            Text(formatter.temperature(temperature)).font(Typography.metric).contentTransition(.numericText())
                            Text(tr("Average of the GPU sensors")).font(Typography.caption).foregroundStyle(.secondary)
                            ProvenanceTag(tr("Derived"))
                        }
                        .frame(maxWidth: 260)
                    }
                }
                SeriesChartCard(
                    title: tr("Usage history"), symbol: "chart.xyaxis.line",
                    lines: [.init(metric: .gpuUsage, label: tr("GPU"), color: .purple)],
                    range: 0...100, transform: { $0 * 100 }, format: { "\(Int($0)) %" }
                )
                TechnicalDetails {
                    InfoRow(tr("Model"), value: gpu.name)
                    if let cores = gpu.coreCount { InfoRow(tr("GPU cores"), value: "\(cores)") }
                    InfoRow(tr("Source"), value: "IOAccelerator · PerformanceStatistics")
                }
            } else {
                WaitingView()
            }
        }
    }
}
