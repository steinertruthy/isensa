import Charts
import SensaCore
import SensaDesign
import SensaInsights
import SensaMonitoring
import SwiftUI

/// The overview's one memorable element: the Mac's state in a sentence, over a live
/// waveform of CPU and GPU activity — the only ambient motion in the app.
struct PulseHero: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    let health: SystemHealth?

    var body: some View {
        let level = health?.level ?? .normal
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: level.symbolName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(level.tint)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(InsightText.headline(for: health)).font(Typography.title)
                    insights
                }
                Spacer(minLength: Spacing.medium)
                legend
            }
            .padding([.horizontal, .top], Spacing.large + Spacing.xSmall)
            PulseChart()
                .frame(height: 110)
                .padding(.top, Spacing.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(radius: Radius.xLarge)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xLarge, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("dashboard.health")
    }

    @ViewBuilder private var insights: some View {
        let items = health?.items ?? []
        if items.isEmpty {
            Text(tr("Temperature, memory, storage and battery are within the expected range."))
                .font(Typography.callout).foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                ForEach(items) { item in
                    Label {
                        Text(InsightText(formatter: settings.formatter).text(for: item.insight))
                    } icon: {
                        Image(systemName: item.level == .normal ? item.component.symbolName : item.level.symbolName)
                            .foregroundStyle(item.level == .normal ? item.component.hue.color : item.level.tint)
                    }
                    .font(Typography.callout)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: Spacing.large) {
            legendItem(tr("CPU"), hue: .cpu, value: store.snapshot.cpu?.totalUsage)
            legendItem(tr("GPU"), hue: .gpu, value: store.snapshot.gpu?.deviceUtilization)
        }
    }

    private func legendItem(_ title: String, hue: Hue, value: Double?) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 5) {
                Circle().fill(hue.color).frame(width: 7, height: 7)
                Text(title).font(Typography.caption).foregroundStyle(.secondary)
            }
            MetricText(value.map { settings.formatter.percent($0) } ?? "–", size: .medium, rolls: false)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Full-bleed dual waveform. Each series is observed on its own, so only this view redraws.
private struct PulseChart: View {
    @Environment(MetricsStore.self) private var store

    var body: some View {
        let cpu = store.series(for: .cpuUsage).points()
        let gpu = store.series(for: .gpuUsage).points()
        let domain = SeriesSparkline.utilizationRange(cpu.map(\.value) + gpu.map(\.value))
        Chart {
            ForEach(gpu) { point in
                AreaMark(x: .value("Time", point.date), yStart: .value("Base", 0), yEnd: .value("GPU", point.value), series: .value("Series", "GPU"))
                    .foregroundStyle(LinearGradient(colors: [Hue.gpu.color.opacity(0.28), Hue.gpu.color.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", point.date), y: .value("GPU", point.value), series: .value("Series", "GPU line"))
                    .foregroundStyle(Hue.gpu.color.opacity(0.9))
                    .lineStyle(StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
            ForEach(cpu) { point in
                AreaMark(x: .value("Time", point.date), yStart: .value("Base", 0), yEnd: .value("CPU", point.value), series: .value("Series", "CPU"))
                    .foregroundStyle(LinearGradient(colors: [Hue.cpu.color.opacity(0.32), Hue.cpu.color.opacity(0.02)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", point.date), y: .value("CPU", point.value), series: .value("Series", "CPU line"))
                    .foregroundStyle(Hue.cpu.color)
                    .lineStyle(StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .interpolationMethod(.monotone)
            }
        }
        .chartYScale(domain: domain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { $0.clipped() }
        .accessibilityHidden(true)
    }
}
