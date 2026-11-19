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
        ScreenContainer(title: tr("Fans"), summary: Descriptions.fans(fans)) {
            if fans.isEmpty {
                WaitingView()
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: Spacing.large)], spacing: Spacing.large) {
                ForEach(fans) { fan in
                    Card(tr("Fan %@", "\(fan.id + 1)"), symbol: "fan", accessory: {
                        ProvenanceTag(fan.isAutomatic ? tr("Automatic") : tr("Manual"), symbol: fan.isAutomatic ? "a.circle" : "hand.raised")
                    }) {
                        Text(formatter.rpm(fan.currentRPM)).font(Typography.metric).contentTransition(.numericText())
                        if let relative = fan.relativeSpeed {
                            ProgressView(value: relative).tint(.teal)
                                .accessibilityLabel(tr("Speed within the supported range"))
                        }
                        if let minimum = fan.minimumRPM, let maximum = fan.maximumRPM {
                            Text(tr("Range %@ – %@", formatter.rpm(minimum), formatter.rpm(maximum)))
                                .font(Typography.caption).foregroundStyle(.secondary)
                        }
                        SeriesSparkline(metric: .fanSpeed(fan.id), tint: .teal).frame(height: 44)
                    }
                }
            }
            if fans.contains(where: { $0.currentRPM < 1 }) {
                Text(tr("Fans on this Mac stop completely when cooling is not needed. That is normal behaviour."))
                    .font(Typography.caption).foregroundStyle(.secondary)
            }
            controlNotice
        }
    }

    @ViewBuilder private var controlNotice: some View {
        switch store.capabilities[.fanControl] {
        case .requiresAuthorization(.signedPrivilegedHelper)?:
            CapabilityNotice(
                symbol: "lock.shield",
                title: tr("Fan control is locked"),
                message: Copy.fanControlLocked
            )
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
