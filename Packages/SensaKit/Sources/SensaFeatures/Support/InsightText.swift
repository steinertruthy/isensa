import SensaCore
import SensaInsights

/// Friendly, specific sentences for insights — the only place they are worded.
struct InsightText {
    let formatter: MetricFormatter

    func text(for insight: Insight) -> String {
        switch insight {
        case .memoryPressure(.critical):
            tr("Memory pressure is critical. macOS is running low on available memory.")
        case .memoryPressure:
            tr("Memory pressure is elevated. Closing apps you are not using may help.")
        case .thermalState(.critical):
            tr("Critical temperature: macOS is strongly limiting performance.")
        case .thermalState:
            tr("Your Mac is hot and has reduced performance to protect itself.")
        case let .batteryLow(charge):
            tr("Battery is low (%@). Connect the charger.", formatter.percent(charge))
        case let .batteryCharging(_, minutes?):
            tr("The battery is charging — full in about %@.", formatter.duration(minutes: minutes))
        case .batteryCharging:
            tr("The battery is charging.")
        case let .batteryServiceRecommended(condition):
            tr("macOS recommends checking the battery (%@).", condition)
        case let .storageNearlyFull(volume, fraction):
            tr("The disk “%@” is %@ full.", volume, formatter.percent(fraction))
        case .ssdCriticalWarning:
            tr("The internal SSD reports a critical condition. Back up your data.")
        case let .ssdMediaErrors(count):
            tr("The internal SSD has recorded %@ media errors. Keep your backups current.", formatter.integer(Int(clamping: count)))
        }
    }

    static func headline(for health: SystemHealth?) -> String {
        guard let health else { return tr("Gathering information…") }
        switch health.level {
        case .normal: return tr("Your Mac is running normally.")
        case .attention: return tr("A few things deserve your attention.")
        case .critical: return tr("Your Mac needs attention.")
        }
    }

    static func levelName(_ level: HealthLevel) -> String {
        switch level {
        case .normal: tr("Normal")
        case .attention: tr("Attention")
        case .critical: tr("Critical")
        }
    }
}
