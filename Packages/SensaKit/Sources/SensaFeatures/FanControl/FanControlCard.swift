import Charts
import SensaControl
import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

/// Fan control on the Fans screen: mode, its settings, what is in effect and why.
struct FanControlCard: View {
    let coordinator: FanControlCoordinator
    @Environment(AppSettings.self) private var settings
    @Environment(MetricsStore.self) private var store
    @Environment(\.feedback) private var feedback

    var body: some View {
        Card(tr("Control"), accessory: { ProvenanceTag(tr("Experimental"), symbol: "flask") }) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                switch coordinator.helperState {
                case .ready:
                    controls
                case .notInstalled:
                    helperPrompt(title: tr("Install the fan helper"), button: tr("Install Helper…"))
                case .needsUpdate:
                    helperPrompt(title: tr("The fan helper needs an update"), button: tr("Update Helper…"))
                case let .unreachable(reason):
                    helperPrompt(title: tr("The fan helper is not responding"), button: tr("Install Again…"), detail: reason)
                }
                if let problem = coordinator.problem {
                    FanProblemView(problem: problem) { Task { await coordinator.retry() } }
                }
            }
        }
        .task { await coordinator.refreshState() }
    }

    // MARK: - Controls

    @ViewBuilder private var controls: some View {
        @Bindable var settings = settings
        Picker(tr("Mode"), selection: kind) {
            ForEach(FanModeKind.allCases) { Text(FanControlText.modeTitle($0)).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityIdentifier("fans.mode")

        switch settings.fanMode {
        case .automatic:
            EmptyView()
        case let .fixed(fraction):
            fixedSpeed(fraction)
        case let .curve(preset):
            curve(preset)
        }
        status
        Text(FanControlText.safety).font(Typography.caption).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var kind: Binding<FanModeKind> {
        Binding(
            get: { FanModeKind(settings.fanMode) },
            set: { kind in
                feedback.perform(.selection)
                switch kind {
                case .automatic: settings.fanMode = .automatic
                case .fixed: settings.fanMode = .fixed(fraction: 0.5)
                case .curve: settings.fanMode = .curve(.balanced)
                }
                Task { await coordinator.tick() }
            }
        )
    }

    private func fixedSpeed(_ fraction: Double) -> some View {
        let fan = store.snapshot.sensors?.fans.first
        let limits = fan.flatMap { fan in
            fan.minimumRPM.flatMap { minimum in fan.maximumRPM.map { FanLimits(index: fan.id, minimumRPM: minimum, maximumRPM: $0) } }
        }
        return VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack {
                Text(tr("Speed"))
                Spacer()
                if let limits {
                    Text(settings.formatter.rpm(limits.rpm(atFraction: fraction))).monospacedDigit().foregroundStyle(.secondary)
                }
            }
            Slider(
                value: Binding(get: { fraction }, set: { settings.fanMode = .fixed(fraction: ($0 * 20).rounded() / 20) }),
                in: 0...1
            ) {
                Text(tr("Speed"))
            } minimumValueLabel: {
                Image(systemName: "fan").imageScale(.small)
            } maximumValueLabel: {
                Image(systemName: "fan.fill").imageScale(.medium)
            }
            .labelsHidden()
            .accessibilityIdentifier("fans.speed")
        }
    }

    private func curve(_ preset: FanCurve.Preset) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker(tr("Curve"), selection: Binding(get: { preset }, set: { settings.fanMode = .curve($0) })) {
                ForEach(FanCurve.Preset.allCases, id: \.self) { Text(FanControlText.presetTitle($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("fans.preset")
            Text(FanControlText.presetDescription(preset, formatter: settings.formatter)).font(Typography.callout).foregroundStyle(.secondary)
            FanCurveChart(curve: preset.curve, temperature: store.snapshot.sensors?.cpuTemperature, formatter: settings.formatter)
                .frame(height: 130)
        }
    }

    @ViewBuilder private var status: some View {
        if coordinator.isApplying || coordinator.isReleasing {
            Label {
                Text(coordinator.isApplying ? tr("Switching the fans to manual control…") : tr("Returning the fans to macOS…"))
            } icon: {
                ProgressView().controlSize(.small)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("fans.status")
        } else {
            planStatus
        }
    }

    @ViewBuilder private var planStatus: some View {
        switch coordinator.plan {
        case let .manual(targets):
            Label {
                Text(tr("Sensa is controlling the fans: %@.", Self.targetSummary(targets, formatter: settings.formatter)))
            } icon: {
                Image(systemName: "fan.fill").foregroundStyle(Hue.fans.color)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("fans.status")
        case let .system(reason):
            Label(FanControlText.systemReason(reason), systemImage: "apple.logo")
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("fans.status")
        }
    }

    /// One value when every fan shares it (the usual case), otherwise each fan's.
    static func targetSummary(_ targets: [FanTarget], formatter: MetricFormatter) -> String {
        var seen: [String] = []
        for value in targets.map({ formatter.rpm($0.rpm) }) where !seen.contains(value) { seen.append(value) }
        return seen.joined(separator: " · ")
    }

    // MARK: - Helper

    private func helperPrompt(title: String, button: String, detail: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Label(title, systemImage: "lock.shield").font(Typography.headline)
            Text(FanControlText.helperExplanation).font(Typography.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail { Text(detail).font(Typography.caption).foregroundStyle(.secondary) }
            HStack {
                Button(button) { Task { await coordinator.installHelper() } }
                    .disabled(coordinator.isInstalling)
                    .accessibilityIdentifier("fans.install")
                if coordinator.isInstalling { ProgressView().controlSize(.small) }
            }
        }
    }
}

/// A problem in plain words, with the technical detail underneath (selectable, for reports).
struct FanProblemView: View {
    let problem: FanControlProblem
    var retry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(FanControlText.problem(problem), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
            Text(problem.detail).font(Typography.caption).foregroundStyle(.secondary).textSelection(.enabled)
            if case .notApplied = problem, let retry {
                Button(tr("Try Again"), action: retry).accessibilityIdentifier("fans.retry")
            }
        }
        .accessibilityIdentifier("fans.problem")
    }
}

/// The selected curve, with the macOS-controlled zone shaded and the current temperature marked.
private struct FanCurveChart: View {
    let curve: FanCurve
    let temperature: Double?
    let formatter: MetricFormatter

    var body: some View {
        let points = stride(from: 30.0, through: 100, by: 1).map { ($0, curve.fraction(at: $0)) }
        Chart {
            if let quiet = curve.systemControlBelow {
                RectangleMark(xStart: .value("From", 30), xEnd: .value("To", quiet), yStart: .value("Bottom", 0), yEnd: .value("Top", 1))
                    .foregroundStyle(Color.secondary.opacity(0.08))
                    .annotation(position: .overlay, alignment: .center) {
                        Text("macOS").font(Typography.caption).foregroundStyle(.secondary)
                    }
            }
            ForEach(points, id: \.0) { point in
                LineMark(x: .value("Temperature", point.0), y: .value("Speed", point.1))
                    .foregroundStyle(Hue.fans.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            if let temperature {
                RuleMark(x: .value("Now", min(max(temperature, 30), 100)))
                    .foregroundStyle(Hue.thermal.color)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .center) {
                        Text(formatter.temperature(temperature)).font(Typography.caption).foregroundStyle(Hue.thermal.color)
                    }
            }
        }
        .chartXScale(domain: 30...100)
        .chartYScale(domain: 0...1)
        .chartYAxis {
            AxisMarks(values: [0, 0.5, 1]) { value in
                AxisGridLine()
                AxisValueLabel { Text(value.as(Double.self).map { $0 == 0 ? tr("Min") : $0 == 1 ? tr("Max") : "50%" } ?? "") }
            }
        }
        .chartXAxis {
            AxisMarks(values: [40, 60, 80, 100]) { value in
                AxisGridLine()
                AxisValueLabel { Text(value.as(Double.self).map { formatter.temperature($0) } ?? "") }
            }
        }
        .accessibilityLabel(tr("Fan curve"))
    }
}
