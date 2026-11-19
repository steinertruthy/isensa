import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct FansScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.services) private var services

    var body: some View {
        let formatter = settings.formatter
        let fans = store.snapshot.sensors?.fans ?? []
        ScreenContainer(title: tr("Fans"), summary: Descriptions.fans(fans), symbol: "fan", hue: .fans) {
            if fans.isEmpty { WaitingView() }
            CellGroup {
                ForEach(Array(fans.enumerated()), id: \.element.id) { index, fan in
                    if index > 0 { CellDivider() }
                    let target = target(for: fan)
                    MetricCell(
                        title: tr("Fan %@", "\(fan.id + 1)"), symbol: "fan", hue: .fans,
                        value: FanFormatting.value(fan, display: settings.fanSpeedDisplay, formatter: formatter),
                        caption: target.map { FanFormatting.progress(fan, target: $0, display: settings.fanSpeedDisplay, formatter: formatter) }
                            ?? range(fan, formatter: formatter)
                    ) {
                        SeriesSparkline(metric: .fanSpeed(fan.id), tint: Hue.fans.color, reference: target)
                    }
                }
            }
            .opacity(fans.isEmpty ? 0 : 1)
            if fans.contains(where: { $0.currentRPM < 1 }) {
                Text(tr("Fans on this Mac stop completely when cooling is not needed. That is normal behaviour."))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
            if let coordinator = services.fanControl, !fans.isEmpty {
                FanControlCard(coordinator: coordinator)
            }
        }
    }

    /// The speed the fan is being driven to, when it is under manual control: read from the
    /// controller itself, or what Sensa asked for while the change is being applied.
    private func target(for fan: FanReading) -> Double? {
        if !fan.isAutomatic, let target = fan.targetRPM, target > 0 { return target }
        if case let .manual(targets)? = services.fanControl?.plan { return targets.first { $0.index == fan.id }?.rpm }
        return nil
    }

    private func range(_ fan: FanReading, formatter: MetricFormatter) -> String {
        guard let minimum = fan.minimumRPM, let maximum = fan.maximumRPM else {
            return fan.isAutomatic ? tr("Automatic") : tr("Manual")
        }
        return tr("Range %@ – %@", formatter.rpm(minimum), formatter.rpm(maximum))
    }
}

/// Fan speed in the user's preferred form (Settings › Fans).
enum FanFormatting {
    /// Within this share of the target, a fan counts as holding it (tachometers and the firmware's
    /// control loop normally leave a difference of a few percent).
    static let onTargetTolerance = 0.05

    enum Progress: Equatable {
        case holding, speedingUp, slowingDown
    }

    static func value(_ fan: FanReading, display: FanSpeedDisplay, formatter: MetricFormatter) -> String {
        format(fan.currentRPM, fan: fan, display: display, formatter: formatter)
    }

    static func progress(current: Double, target: Double) -> Progress {
        guard target > 0 else { return .holding }
        let difference = (current - target) / target
        if abs(difference) <= onTargetTolerance { return .holding }
        return difference < 0 ? .speedingUp : .slowingDown
    }

    /// "Holding the 4,559 rpm target", "Speeding up to 4,559 rpm", "Slowing down to 4,559 rpm".
    static func progress(_ fan: FanReading, target: Double, display: FanSpeedDisplay, formatter: MetricFormatter) -> String {
        let value = format(target, fan: fan, display: display, formatter: formatter)
        return switch progress(current: fan.currentRPM, target: target) {
        case .holding: tr("Holding the %@ target", value)
        case .speedingUp: tr("Speeding up to %@", value)
        case .slowingDown: tr("Slowing down to %@", value)
        }
    }

    private static func format(_ rpm: Double, fan: FanReading, display: FanSpeedDisplay, formatter: MetricFormatter) -> String {
        if display == .percentOfRange, let minimum = fan.minimumRPM, let maximum = fan.maximumRPM, maximum > minimum {
            return formatter.percent(min(max((rpm - minimum) / (maximum - minimum), 0), 1))
        }
        return formatter.rpm(rpm)
    }
}
