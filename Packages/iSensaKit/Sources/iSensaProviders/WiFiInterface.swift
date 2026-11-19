import CoreWLAN

/// BSD names of Wi-Fi interfaces (public CoreWLAN; no Location permission needed for names).
enum WiFiInterface {
    static let names: Set<String> = Set(CWWiFiClient.shared().interfaceNames() ?? [])
}
