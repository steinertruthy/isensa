import Charts
import iSensaCore
import iSensaDesign
import iSensaInsights
import iSensaMonitoring
import SwiftUI
import UniformTypeIdentifiers

/// Recorded history: one range chart per metric (min–max band, average line) and the alerts
/// that fired. Data stays on this Mac; export writes CSV or JSON where the user chooses.
struct HistoryScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services
    @Environment(\.feedback) private var feedback
    @State private var period: HistoryPeriod = .day
    @State private var series: [MetricID: [HistoryPoint]] = [:]
    /// The period before, already moved onto the current time axis.
    @State private var previous: [MetricID: [HistoryPoint]] = [:]
    @AppStorage("historyComparesPrevious") private var comparesPrevious = false
    /// The period shown, so every chart (and the previous period) shares one time axis.
    @State private var window = Date().addingTimeInterval(-86_400)...Date()
    @State private var events: [HistoryEvent] = []
    @State private var isLoading = true
    @State private var export: HistoryDocument?
    @State private var exportError: String?

    var body: some View {
        let formatter = settings.formatter
        let metrics = HistoryMetric.all(formatter: formatter, hasBattery: store.profile.hasBattery, fanCount: store.profile.fanCount)
        ScreenContainer(title: tr("History"), summary: summary, symbol: "clock.arrow.circlepath", hue: .neutral) {
            HStack {
                Picker(tr("Period"), selection: $period) {
                    ForEach(HistoryPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 360)
                Toggle(tr("Compare with previous period"), isOn: $comparesPrevious)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("history.compare")
                Spacer()
                Menu(tr("Export…")) {
                    Button(tr("CSV (spreadsheets)")) { prepareExport(.csv) }
                    Button(tr("JSON")) { prepareExport(.json) }
                }
                .fixedSize()
                .disabled(series.values.allSatisfy(\.isEmpty))
            }
            if !settings.historyEnabled {
                CapabilityNotice(symbol: "pause.circle", title: tr("History is paused"), message: tr("Turn it on in Settings › History to keep a record."))
            }
            if isLoading {
                WaitingView(message: tr("Loading history…"))
            } else if series.values.allSatisfy(\.isEmpty) {
                ContentUnavailableView(
                    tr("No history yet"), systemImage: "clock",
                    description: Text(store.isDemo
                        ? tr("History is not recorded while iSensa shows demo data.")
                        : tr("iSensa records a summary every minute while it runs. Check back in a few minutes."))
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                let patterns = HistoryPatternFinder.patterns(in: series)
                if !patterns.isEmpty { PatternsCard(patterns: patterns, period: period, formatter: formatter) }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Spacing.large)], spacing: Spacing.large) {
                    ForEach(metrics) { metric in
                        if let points = series[metric.metric], !points.isEmpty {
                            RangeChartCard(
                                metric: metric, points: points, window: window, period: period,
                                previous: comparesPrevious ? previous[metric.metric] : nil
                            )
                        }
                    }
                }
                EventsCard(events: events, formatter: formatter)
            }
        }
        .task(id: TaskKey(period: period, enabled: settings.historyEnabled, compares: comparesPrevious)) {
            await reloadPeriodically(metrics: metrics)
        }
        .fileExporter(
            isPresented: Binding(get: { export != nil }, set: { if !$0 { export = nil } }),
            document: export, contentType: export?.contentType ?? .commaSeparatedText,
            defaultFilename: export?.filename
        ) { result in
            switch result {
            case .success: feedback.perform(.success)
            case let .failure(error): exportError = error.localizedDescription
            }
        }
        .alert(tr("Export failed"), isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button(tr("OK")) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private struct TaskKey: Equatable {
        let period: HistoryPeriod
        let enabled: Bool
        let compares: Bool
    }

    private var summary: String {
        tr("Kept on this Mac for %@.", retentionText(settings.historyRetention))
    }

    private func retentionText(_ retention: HistoryRetention) -> String {
        switch retention {
        case .day: tr("1 day")
        case .week: tr("7 days")
        case .month: tr("30 days")
        case .quarter: tr("90 days")
        }
    }

    /// Loads the period, then refreshes every minute while the screen is visible.
    private func reloadPeriodically(metrics: [HistoryMetric]) async {
        isLoading = series.isEmpty
        while !Task.isCancelled {
            await load(metrics: metrics)
            isLoading = false
            try? await Task.sleep(for: .seconds(60))
        }
    }

    private func load(metrics: [HistoryMetric]) async {
        guard let history = services.history else { return }
        let to = Date()
        let from = to.addingTimeInterval(-period.duration)
        var loaded: [MetricID: [HistoryPoint]] = [:]
        var before: [MetricID: [HistoryPoint]] = [:]
        for metric in metrics {
            loaded[metric.metric] = (try? await history.points(metric: metric.metric, from: from, to: to, resolution: period.resolution)) ?? []
            if comparesPrevious {
                let earlier = (try? await history.points(
                    metric: metric.metric, from: from.addingTimeInterval(-period.duration), to: from, resolution: period.resolution
                )) ?? []
                before[metric.metric] = HistoryComparison.shifted(earlier, by: period.duration)
            }
        }
        series = loaded
        previous = before
        window = from...to
        events = (try? await history.events(from: from, to: to)) ?? []
    }

    private func prepareExport(_ format: HistoryExportFormat) {
        guard let history = services.history else { return }
        let to = Date()
        let from = to.addingTimeInterval(-period.duration)
        Task {
            do {
                let data = try await history.export(format: format, from: from, to: to)
                export = HistoryDocument(data: data, format: format)
            } catch {
                exportError = error.localizedDescription
            }
        }
    }
}

private struct RangeChartCard: View {
    let metric: HistoryMetric
    let points: [HistoryPoint]
    let window: ClosedRange<Date>
    let period: HistoryPeriod
    /// The previous period on the same time axis, when comparing.
    var previous: [HistoryPoint]?

    var body: some View {
        let average = HistoryComparison.average(points) ?? 0
        let peak = points.map(\.maximum).max() ?? 0
        let previousAverage = previous.flatMap(HistoryComparison.average)
        Card(metric.title) {
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Average")).font(Typography.caption).foregroundStyle(.secondary)
                    MetricText(metric.format(average), size: .medium)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Peak")).font(Typography.caption).foregroundStyle(.secondary)
                    MetricText(metric.format(peak), size: .medium)
                }
                if let previousAverage {
                    PreviousAverage(text: metric.format(previousAverage), trend: HistoryComparison.trend(current: average, previous: previousAverage))
                }
            }
            // Lines break where nothing was recorded for more than three buckets.
            let gap = TimeInterval(period.resolution.rawValue * 3)
            Chart {
                ForEach(HistoryComparison.segmented(points, maximumGap: gap)) { item in
                    AreaMark(
                        x: .value("Time", item.point.date),
                        yStart: .value("Minimum", item.point.minimum),
                        yEnd: .value("Maximum", item.point.maximum),
                        series: .value("Segment", "current-\(item.segment)")
                    )
                    .foregroundStyle(metric.hue.color.opacity(0.18))
                    .interpolationMethod(.monotone)
                    LineMark(
                        x: .value("Time", item.point.date), y: .value("Average", item.point.average),
                        series: .value("Segment", "current-\(item.segment)")
                    )
                        .foregroundStyle(metric.hue.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                }
                ForEach(HistoryComparison.segmented(previous ?? [], maximumGap: gap)) { item in
                    LineMark(
                        x: .value("Time", item.point.date), y: .value("Average", item.point.average),
                        series: .value("Segment", "previous-\(item.segment)")
                    )
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 3]))
                        .interpolationMethod(.monotone)
                }
            }
            .chartXScale(domain: window)
            .chartXAxis {
                AxisMarks(values: period.axisTicks(in: window)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    AxisValueLabel(format: period.axisStep >= 86_400 ? .dateTime.day().month(.abbreviated) : .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel { if let number = value.as(Double.self) { Text(metric.format(number)) } }
                }
            }
            .chartPlotStyle { $0.clipped() }
            .frame(height: 130)
            .accessibilityElement()
            .accessibilityLabel(metric.title)
            .accessibilityValue(tr("Average %@, peak %@", metric.format(average), metric.format(peak)))
            if let previous, previous.isEmpty {
                Text(tr("No history for the previous period yet."))
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            } else if previous != nil {
                HStack(spacing: Spacing.medium) {
                    LegendSwatch(color: metric.hue.color, dashed: false, title: tr("This period"))
                    LegendSwatch(color: .secondary, dashed: true, title: tr("Previous period"))
                }
                .font(Typography.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

/// The previous period's average, with an arrow showing how the current period changed from it
/// (up, down, or about the same within 5 %).
private struct PreviousAverage: View {
    let text: String
    let trend: HistoryComparison.Trend

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(tr("Previous period")).font(Typography.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xxSmall) {
                MetricText(text, size: .medium).foregroundStyle(.secondary)
                Image(systemName: symbol).font(Typography.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tr("Previous period"))
        .accessibilityValue("\(text), \(description)")
    }

    private var symbol: String {
        switch trend {
        case .higher: "arrow.up.right"
        case .lower: "arrow.down.right"
        case .steady: "equal"
        }
    }

    private var description: String {
        switch trend {
        case .higher: tr("Now higher than the previous period")
        case .lower: tr("Now lower than the previous period")
        case .steady: tr("About the same as the previous period")
        }
    }
}

private struct LegendSwatch: View {
    let color: Color
    let dashed: Bool
    let title: String

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 16, y: 1))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: dashed ? [4, 3] : []))
            .frame(width: 16, height: 2)
            Text(title)
        }
    }
}

private struct EventsCard: View {
    let events: [HistoryEvent]
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Alerts")) {
            if events.isEmpty {
                Text(tr("No alerts in this period.")).font(Typography.callout).foregroundStyle(.secondary)
            } else {
                ForEach(events) { event in
                    let kind = AlertKind(rawValue: event.kind)
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                        Image(systemName: event.level.symbolName).foregroundStyle(event.level.tint)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(kind.map { AlertText(formatter: formatter).title($0) } ?? event.kind).font(Typography.callout.weight(.medium))
                            if let kind {
                                Text(AlertText(formatter: formatter).body(kind, value: event.value)).font(Typography.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(event.date, format: .dateTime.day().month().hour().minute()).font(Typography.caption).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// Exported history file for the system save panel.
struct HistoryDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.commaSeparatedText, .json]
    let data: Data
    let format: HistoryExportFormat

    init(data: Data, format: HistoryExportFormat) {
        self.data = data
        self.format = format
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        format = configuration.contentType == .json ? .json : .csv
    }

    var contentType: UTType { format == .json ? .json : .commaSeparatedText }

    var filename: String {
        "iSensa History \(Date().formatted(.iso8601.year().month().day())).\(format.rawValue)"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
