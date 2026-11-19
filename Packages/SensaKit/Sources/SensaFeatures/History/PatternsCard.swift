import SensaCore
import SensaDesign
import SensaInsights
import SwiftUI

/// "What changed together" over the period, in cautious words.
struct PatternsCard: View {
    let patterns: [HistoryPattern]
    let period: HistoryPeriod
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("Patterns")) {
            ForEach(Array(patterns.enumerated()), id: \.offset) { _, pattern in
                Label {
                    Text(text(pattern)).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: symbol(pattern)).foregroundStyle(hue(pattern).color)
                }
                .font(Typography.callout)
                .accessibilityElement(children: .combine)
            }
            Text(tr("Based on recorded summaries. Values that change together do not always cause each other."))
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("history.patterns")
    }

    private func text(_ pattern: HistoryPattern) -> String {
        switch pattern {
        case .temperatureFollowsCPU:
            tr("CPU temperature rose and fell with how hard the processor was working.")
        case let .warmWhileCPUIdle(peak):
            tr("The CPU reached %@ while it was mostly idle. Something else, such as the GPU, charging or a warm room, may have contributed.",
               formatter.temperature(peak))
        case let .fansFollowTemperature(start?):
            tr("The fans sped up as the temperature rose, usually from about %@.", formatter.temperature(start))
        case .fansFollowTemperature(nil):
            tr("The fans sped up as the temperature rose.")
        case .fansStayedOff:
            tr("The fans stayed off: the Mac cooled itself without them.")
        case let .temperaturePeak(celsius, date, usage?):
            tr("Hottest moment: %@ at %@, with the CPU at %@.", formatter.temperature(celsius), time(date), formatter.percent(usage))
        case let .temperaturePeak(celsius, date, nil):
            tr("Hottest moment: %@ at %@.", formatter.temperature(celsius), time(date))
        }
    }

    private func time(_ date: Date) -> String {
        period.duration > 86_400
            ? date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
            : date.formatted(.dateTime.hour().minute())
    }

    private func symbol(_ pattern: HistoryPattern) -> String {
        switch pattern {
        case .temperatureFollowsCPU: "cpu"
        case .warmWhileCPUIdle: "thermometer.sun"
        case .fansFollowTemperature, .fansStayedOff: "fan"
        case .temperaturePeak: "thermometer.high"
        }
    }

    private func hue(_ pattern: HistoryPattern) -> Hue {
        switch pattern {
        case .temperatureFollowsCPU: .cpu
        case .warmWhileCPUIdle, .temperaturePeak: .thermal
        case .fansFollowTemperature, .fansStayedOff: .fans
        }
    }
}
