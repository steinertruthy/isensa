import SwiftUI

/// A labelled figure for the facts beside a hero instrument.
public struct Stat: Identifiable {
    public let label: String
    public let value: String
    public let note: String?

    public init(_ label: String, value: String, note: String? = nil) {
        self.label = label
        self.value = value
        self.note = note
    }

    public var id: String { label }
}

/// The top of every detail screen: one instrument (gauge, battery…) and the facts that explain it.
public struct HeroInstrument<Instrument: View>: View {
    private let stats: [Stat]
    private let instrument: Instrument

    public init(stats: [Stat], @ViewBuilder instrument: () -> Instrument) {
        self.stats = stats
        self.instrument = instrument()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.xxLarge) {
            instrument
            Grid(alignment: .topLeading, horizontalSpacing: Spacing.xxLarge, verticalSpacing: Spacing.large) {
                ForEach(rows.indices, id: \.self) { row in
                    GridRow {
                        ForEach(rows[row]) { stat in
                            StatView(stat: stat)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(radius: Radius.xLarge)
    }

    private var rows: [[Stat]] {
        stride(from: 0, to: stats.count, by: 2).map { Array(stats[$0..<min($0 + 2, stats.count)]) }
    }
}

private struct StatView: View {
    let stat: Stat

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(stat.label).font(Typography.caption).foregroundStyle(.secondary)
            MetricText(stat.value, size: .medium)
            if let note = stat.note {
                Text(note).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Ring gauge with a typeset value in the centre.
public struct GaugeInstrument: View {
    private let fraction: Double
    private let hue: Hue
    private let value: String
    private let caption: String

    public init(fraction: Double, hue: Hue, value: String, caption: String) {
        self.fraction = fraction
        self.hue = hue
        self.value = value
        self.caption = caption
    }

    public var body: some View {
        RingGauge(value: fraction, tint: hue.color, lineWidth: 11) {
            VStack(spacing: 0) {
                MetricText(value, size: .large, rolls: false)
                Text(caption).font(Typography.caption).foregroundStyle(.secondary)
            }
            .padding(Spacing.large)
        }
        .frame(width: 136, height: 136)
        .accessibilityElement(children: .combine)
    }
}
