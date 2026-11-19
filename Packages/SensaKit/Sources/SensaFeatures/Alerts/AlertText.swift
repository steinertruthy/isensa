import SensaCore
import SensaInsights

/// Notification and history wording for alerts: what happened, then what to do.
struct AlertText {
    let formatter: MetricFormatter

    func title(_ kind: AlertKind) -> String {
        switch kind {
        case .highTemperature: tr("Your Mac is running hot")
        case .memoryPressure: tr("Memory pressure is high")
        case .lowStorage: tr("Startup disk almost full")
        case .storageFillingFast: tr("Disk space is shrinking fast")
        case .lowBattery: tr("Battery is low")
        case .batteryCharged: tr("Battery charged")
        case .batteryTemperature: tr("Battery is warm")
        case .ssdHealth: tr("SSD reports a problem")
        case .sensorUnavailable: tr("Sensors unavailable")
        }
    }

    func body(_ kind: AlertKind, value: Double?) -> String {
        switch kind {
        case .highTemperature:
            tr("The CPU has been at %@ for a while. Closing demanding apps lets it cool down.", value.map { formatter.temperature($0) } ?? "–")
        case .memoryPressure:
            tr("macOS is working hard to free memory. Closing apps you are not using will help.")
        case .lowStorage:
            Copy.lowStorageBody(value.map { formatter.percent($0) } ?? "–")
        case .storageFillingFast:
            Copy.storageFillingFastBody(value.map { formatter.fileBytes(Int64($0)) } ?? "–")
        case .lowBattery:
            tr("%@ left. Connect the charger to keep working.", value.map { formatter.percent($0) } ?? "–")
        case .batteryCharged:
            tr("The battery reached %@. You can unplug the charger.", value.map { formatter.percent($0) } ?? "–")
        case .batteryTemperature:
            tr("The battery is at %@. Keep the Mac in a cooler place while charging.", value.map { formatter.temperature($0) } ?? "–")
        case .ssdHealth:
            tr("The internal SSD reports a critical condition. Back up your data.")
        case .sensorUnavailable:
            tr("Temperature sensors stopped responding. Sensa keeps retrying automatically.")
        }
    }

    static func ruleName(_ kind: AlertKind) -> String {
        switch kind {
        case .highTemperature: tr("High CPU temperature")
        case .memoryPressure: tr("High memory pressure")
        case .lowStorage: tr("Low disk space")
        case .storageFillingFast: tr("Disk space shrinking fast")
        case .lowBattery: tr("Low battery")
        case .batteryCharged: tr("Battery charged to a level")
        case .batteryTemperature: tr("Warm battery")
        case .ssdHealth: tr("SSD health warning")
        case .sensorUnavailable: tr("Sensors stop responding")
        }
    }
}
