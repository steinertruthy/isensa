// swiftlint:disable line_length
// Long explanatory copy lives here so views stay readable and translators find prose in one place.

enum Copy {
    static var memoryPressureExplanation: String {
        tr("Pressure shows whether macOS has to work hard to free memory. A full memory with low pressure is normal: macOS keeps RAM busy with caches to make your Mac faster.")
    }

    static var chargeLimitNote: String {
        tr("Charging limits are managed by macOS. On Apple silicon laptops with recent macOS versions you can set them in System Settings › Battery.")
    }

    static var fanControlLocked: String {
        tr("Changing fan speeds requires Sensa's privileged helper, which macOS only installs for apps signed with an Apple Developer ID. Monitoring keeps working, and your Mac stays under Apple's automatic control.")
    }

    static var privacyStatement: String {
        tr("Sensa does not send metrics, identifiers or any other data to servers. There is no hidden telemetry. Network monitoring reads byte counters only and never inspects traffic.")
    }
}
// swiftlint:enable line_length
