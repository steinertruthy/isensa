import SensaCore
import SensaDesign
import SensaMonitoring
import SwiftUI

struct FansScreen: View {
    @Environment(MetricsStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let formatter = settings.formatter
        let fans = store.snapshot.sensors?.fans ?? []
        ScreenContainer(title: tr("Fans"), summary: Descriptions.fans(fans), symbol: "fan", hue: .fans) {
            if fans.isEmpty { WaitingView() }
            CellGroup {
                ForEach(Array(fans.enumerated()), id: \.element.id) { index, fan in
                    if index > 0 { CellDivider() }
                    MetricCell(
                        title: tr("Fan %@", "\(fan.id + 1)"), symbol: "fan", hue: .fans,
                        value: FanFormatting.value(fan, display: settings.fanSpeedDisplay, formatter: formatter),
                        caption: range(fan, formatter: formatter)
                    ) {
                        SeriesSparkline(metric: .fanSpeed(fan.id), tint: Hue.fans.color)
                    }
                }
            }
            .opacity(fans.isEmpty ? 0 : 1)
            if fans.contains(where: { $0.currentRPM < 1 }) {
                Text(tr("Fans on this Mac stop completely when cooling is not needed. That is normal behaviour."))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
            controlNotice
        }
    }

    private func range(_ fan: FanReading, formatter: MetricFormatter) -> String {
        guard let minimum = fan.minimumRPM, let maximum = fan.maximumRPM else {
            return fan.isAutomatic ? tr("Automatic") : tr("Manual")
        }
        return tr("Range %@ – %@", formatter.rpm(minimum), formatter.rpm(maximum))
    }

    @ViewBuilder private var controlNotice: some View {
        switch store.capabilities[.fanControl] {
        case .requiresAuthorization(.signedPrivilegedHelper)?:
            CapabilityNotice(symbol: "lock.shield", title: tr("Fan control is locked"), message: Copy.fanControlLocked)
        case .requiresAuthorization(.helperApproval)?:
            CapabilityNotice(
                symbol: "person.badge.key",
                title: tr("Approval needed"),
                message: tr("Allow Sensa's helper in System Settings › General › Login Items.")
            )
        default:
            EmptyView()
        }
    }
}

/// Fan speed in the user's preferred form (Settings › Fans).
enum FanFormatting {
    static func value(_ fan: FanReading, display: FanSpeedDisplay, formatter: MetricFormatter) -> String {
        if display == .percentOfRange, let relative = fan.relativeSpeed { return formatter.percent(relative) }
        return formatter.rpm(fan.currentRPM)
    }
}
