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

    static var networkCountersNote: String {
        tr("Sensa only reads byte counters. It never inspects your traffic. macOS reports these counters to apps in 1 KB steps, so very low rates are approximate.")
    }

    static func lowStorageBody(_ free: String) -> String {
        tr("Only %@ of the startup disk is free. Delete files you no longer need or move them to another drive.", free)
    }

    static var onboardingNotifications: String {
        tr("Sensa can tell you when your Mac runs hot, memory is under pressure, the disk is almost full or the battery is low.")
    }

    static var soundsExplanation: String {
        tr("Sensa plays a soft sound only when an action completes or an alert needs you. It stays silent when interface sound effects are off in System Settings › Sound.")
    }

    static var energyExplanation: String {
        tr("Sensa also pauses while your Mac sleeps and slows down while the display is off. Process lists, clock speeds and Wi-Fi details are only read while a window or the menu bar panel is open.")
    }

    static var privacyStatement: String {
        tr("Sensa does not send metrics, identifiers or any other data to servers. There is no hidden telemetry. Network monitoring reads byte counters only and never inspects traffic.")
    }
}
// swiftlint:enable line_length
