import Charts
import iSensaControl
import iSensaCore
import iSensaDesign
import iSensaMonitoring
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
        case .curve, .custom:
            curveSection
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

    private var curveSection: some View {
        let choice = FanCurveChoice(settings.fanMode) ?? .balanced
        let curve = settings.fanMode.curve ?? FanCurve.Preset.balanced.curve
        let description = FanControlText.curveDescription(choice, curve: curve, formatter: settings.formatter)
        return VStack(alignment: .leading, spacing: Spacing.medium) {
            Picker(tr("Curve"), selection: Binding(get: { choice }, set: { select($0, from: choice) })) {
                ForEach(FanCurveChoice.allCases) { Text(FanControlText.curveTitle($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("fans.preset")
            Text(description).font(Typography.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            FanCurveChart(
                curve: curve,
                temperature: coordinator.controlTemperature,
                formatter: settings.formatter,
                onMove: choice == .custom ? { edit(curve.moving(pointAt: $0, celsius: $1, fraction: $2)) } : nil
            )
            .frame(height: choice == .custom ? 170 : 130)
            .accessibilityValue(description)
            if choice == .custom {
                CustomCurveControls(curve: curve, formatter: settings.formatter, onChange: edit)
            }
            Text(tr("The curve follows the hottest CPU core, averaged over a few seconds so brief spikes don't change the fan speed."))
                .font(Typography.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func select(_ choice: FanCurveChoice, from previous: FanCurveChoice) {
        feedback.perform(.selection)
        if let preset = choice.preset {
            settings.fanMode = .curve(preset)
            return
        }
        // A first custom curve starts from the preset the user was looking at.
        if settings.customFanCurve == FanCurve.Preset.balanced.curve, let preset = previous.preset {
            settings.customFanCurve = preset.curve
        }
        settings.fanMode = .custom(settings.customFanCurve)
    }

    private func edit(_ curve: FanCurve) {
        settings.customFanCurve = curve
        settings.fanMode = .custom(curve)
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
                Text(tr("iSensa is controlling the fans: %@.", Self.targetSummary(targets, formatter: settings.formatter)))
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
