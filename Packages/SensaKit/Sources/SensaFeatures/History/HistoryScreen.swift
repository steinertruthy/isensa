import Charts
import SensaCore
import SensaDesign
import SensaInsights
import SensaMonitoring
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
    @State private var events: [HistoryEvent] = []
    @State private var isLoading = true
    @State private var export: HistoryDocument?
    @State private var exportError: String?

    var body: some View {
        let formatter = settings.formatter
        let metrics = HistoryMetric.all(formatter: formatter, hasBattery: store.profile.hasBattery)
        ScreenContainer(title: tr("History"), summary: summary, symbol: "clock.arrow.circlepath", hue: .neutral) {
            HStack {
                Picker(tr("Period"), selection: $period) {
                    ForEach(HistoryPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 360)
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
                        ? tr("History is not recorded while Sensa shows demo data.")
                        : tr("Sensa records a summary every minute while it runs. Check back in a few minutes."))
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: Spacing.large)], spacing: Spacing.large) {
                    ForEach(metrics) { metric in
                        if let points = series[metric.metric], !points.isEmpty {
                            RangeChartCard(metric: metric, points: points)
                        }
                    }
                }
                EventsCard(events: events, formatter: formatter)
            }
        }
        .task(id: TaskKey(period: period, enabled: settings.historyEnabled)) { await reloadPeriodically(metrics: metrics) }
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
        for metric in metrics {
            loaded[metric.metric] = (try? await history.points(metric: metric.metric, from: from, to: to, resolution: period.resolution)) ?? []
        }
        series = loaded
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

    var body: some View {
        let average = points.map(\.average).reduce(0, +) / Double(max(points.count, 1))
        let peak = points.map(\.maximum).max() ?? 0
        Card(metric.title) {
            HStack(spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Average")).font(Typography.caption).foregroundStyle(.secondary)
                    MetricText(metric.format(average), size: .medium)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Peak")).font(Typography.caption).foregroundStyle(.secondary)
                    MetricText(metric.format(peak), size: .medium)
                }
            }
            Chart(points) { point in
                AreaMark(x: .value("Time", point.date), yStart: .value("Minimum", point.minimum), yEnd: .value("Maximum", point.maximum))
                    .foregroundStyle(metric.hue.color.opacity(0.18))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Time", point.date), y: .value("Average", point.average))
                    .foregroundStyle(metric.hue.color)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
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
        "Sensa History \(Date().formatted(.iso8601.year().month().day())).\(format.rawValue)"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
