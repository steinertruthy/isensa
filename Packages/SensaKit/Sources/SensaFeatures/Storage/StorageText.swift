import SensaCore

enum StorageText {
    static func connection(_ connection: StorageConnection) -> String? {
        switch connection {
        case .appleFabric, .pciExpress: nil // Internal SSDs: "Internal" already says it.
        case .usb: "USB"
        case .thunderbolt: "Thunderbolt"
        case .sata: "SATA"
        case .diskImage: tr("Disk image")
        case .network: tr("Network")
        case .virtual: tr("Virtual")
        case let .other(name): name
        }
    }
}
