/// Localized names for the sensor catalog (`SensorCatalog.json` in iSensaProviders).
/// Catalog names are English identifiers; unknown names are shown as they are.
enum SensorNames {
    static func localized(_ name: String) -> String {
        switch name {
        case "CPU · Performance cores": tr("CPU · Performance cores")
        case "CPU · Efficiency cores": tr("CPU · Efficiency cores")
        case "GPU": tr("GPU")
        case "Battery": tr("Battery")
        case "Battery gas gauge": tr("Battery gas gauge")
        case "SSD (NAND)": tr("SSD (NAND)")
        case "SoC die (PMU)": tr("SoC die (PMU)")
        default: name
        }
    }
}
