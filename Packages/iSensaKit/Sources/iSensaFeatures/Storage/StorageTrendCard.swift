import iSensaCore
import iSensaDesign
import iSensaInsights
import SwiftUI

/// Where the startup disk is heading, from iSensa's own history: growth per day, an estimate of
/// when it fills up, and how much is written to the SSD each day.
struct StorageTrendCard: View {
    @Environment(\.services) private var services
    @Environment(AppSettings.self) private var settings
    let available: UInt64
    let hasSSDHealth: Bool

    @State private var trend: StorageTrend?
    @State private var writesPerDay: Double?
    @State private var loaded = false

    var body: some View {
        let formatter = settings.formatter
        Card(tr("Trend"), accessory: { ProvenanceTag(tr("Estimated"), symbol: "chart.line.uptrend.xyaxis") }) {
            if services.history == nil || !settings.historyEnabled {
                Text(tr("Turn on history in Settings › History to see how your disk space changes over time."))
                    .foregroundStyle(.secondary)
            } else if !loaded {
                WaitingView(message: tr("Loading history…")).frame(height: 60)
            } else {
                HStack(alignment: .top, spacing: Spacing.xLarge) {
                    figure(trend.map { growth($0.growthPerDay, formatter: formatter) } ?? "–", caption: tr("Change per day"))
                    figure(forecast(formatter: formatter), caption: tr("Until the disk is full"))
                    if hasSSDHealth {
                        figure(writesPerDay.map { formatter.fileBytes(Int64($0)) } ?? "–", caption: tr("Written to the SSD per day"))
                    }
                }
                if trend == nil {
                    Text(tr("iSensa needs two days of history to estimate a trend.")).font(Typography.caption).foregroundStyle(.secondary)
                } else {
                    Text(Copy.trendForecastNote).font(Typography.caption).foregroundStyle(.secondary)
                }
                if hasSSDHealth {
                    Text(Copy.writesNote).font(Typography.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storage.trend")
        .task(id: settings.historyEnabled) { await refresh() }
    }

    private func figure(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(value).font(Typography.metric).monospacedDigit()
            Text(caption).font(Typography.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func growth(_ bytesPerDay: Double, formatter: MetricFormatter) -> String {
        if abs(bytesPerDay) < StorageTrend.stableGrowthPerDay { return tr("Stable") }
        let amount = formatter.fileBytes(Int64(abs(bytesPerDay)))
        return bytesPerDay > 0 ? "+\(amount)" : "−\(amount)"
    }

    private func forecast(formatter: MetricFormatter) -> String {
        guard let trend else { return "–" }
        guard let days = trend.daysUntilFull else { return tr("Not filling up") }
        return tr("About %@", formatter.days(days))
    }

    /// Reloads now and every ten minutes while the screen is open.
    private func refresh() async {
        guard let history = services.history, settings.historyEnabled else { return }
        while !Task.isCancelled {
            let now = Date()
            let used = (try? await history.points(metric: .diskUsed, from: now.addingTimeInterval(-14 * 86_400), to: now, resolution: .hour)) ?? []
            let written = (try? await history.points(metric: .ssdWritten, from: now.addingTimeInterval(-7 * 86_400), to: now, resolution: .hour)) ?? []
            trend = StorageTrend.compute(usedSpace: used, available: available)
            writesPerDay = StorageTrend.writesPerDay(lifetimeWritten: written)
            loaded = true
            try? await Task.sleep(for: .seconds(600))
        }
    }
}
