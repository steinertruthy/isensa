import SensaCore
import SensaDesign
import SwiftUI

/// SMART log of the internal SSD, shown exactly as the drive reports it.
struct SSDHealthCard: View {
    let health: SSDHealth
    let formatter: MetricFormatter

    var body: some View {
        Card(tr("SSD health"), symbol: "internaldrive", accessory: {
            StatusBadge(level: level, text: health.reportsCriticalCondition ? tr("Reported problem") : tr("Normal"))
        }) {
            HStack(alignment: .top, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(formatter.percent(Double(health.percentageUsed) / 100)).font(Typography.metric)
                    Text(tr("Endurance used, as estimated by the drive")).font(Typography.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(formatter.fileBytes(health.bytesWritten)).font(Typography.metric)
                    Text(tr("Written over its lifetime")).font(Typography.caption).foregroundStyle(.secondary)
                }
            }
            Text(tr("Sensa shows the drive's own estimate and does not predict a remaining lifespan."))
                .font(Typography.caption).foregroundStyle(.secondary)
        }
    }

    /// SMART fields for the screen's technical details section.
    @ViewBuilder
    static func detailRows(_ health: SSDHealth, formatter: MetricFormatter) -> some View {
        InfoRow(tr("Available spare"), value: "\(health.availableSpare) % (\(tr("threshold")) \(health.availableSpareThreshold) %)")
        if let temperature = health.temperature { InfoRow(tr("SSD temperature"), value: formatter.temperature(temperature)) }
        InfoRow(tr("Data read"), value: formatter.fileBytes(health.bytesRead))
        InfoRow(tr("Power-on hours"), value: formatter.integer(Int(clamping: health.powerOnHours)))
        InfoRow(tr("Power cycles"), value: formatter.integer(Int(clamping: health.powerCycles)))
        InfoRow(tr("Unexpected shutdowns"), value: formatter.integer(Int(clamping: health.unsafeShutdowns)))
        InfoRow(tr("Media errors"), value: formatter.integer(Int(clamping: health.mediaErrors)))
        InfoRow(tr("SMART source"), value: "IONVMeSMARTInterface")
    }

    private var level: HealthLevel {
        if health.reportsCriticalCondition { return .critical }
        return health.mediaErrors > 0 ? .attention : .normal
    }
}
