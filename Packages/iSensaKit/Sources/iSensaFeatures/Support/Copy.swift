// swiftlint:disable line_length
// Long explanatory copy lives here so views stay readable and translators find prose in one place.

enum Copy {
    static var memoryPressureExplanation: String {
        tr("Pressure shows whether macOS has to work hard to free memory. A full memory with low pressure is normal: macOS keeps RAM busy with caches to make your Mac faster.")
    }

    static var chargeLimitNote: String {
        tr("Charging limits are managed by macOS. On Apple silicon laptops with recent macOS versions you can set them in System Settings › Battery.")
    }

    static var networkCountersNote: String {
        tr("iSensa only reads byte counters. It never inspects your traffic. macOS reports these counters to apps in 1 KB steps, so very low rates are approximate.")
    }

    static func lowStorageBody(_ free: String) -> String {
        tr("Only %@ of the startup disk is free. Delete files you no longer need or move them to another drive.", free)
    }

    static func storageFillingFastBody(_ lost: String) -> String {
        tr("The startup disk lost %@ of free space in the last 30 minutes. Storage › Activity by app shows what is writing.", lost)
    }

    static var purgeableExplanation: String {
        tr("Purgeable space holds caches, local snapshots and iCloud files kept on this Mac. macOS frees it on its own when an app needs room, so Finder counts it as available.")
    }

    static var snapshotsExplanation: String {
        tr("Snapshots record the disk at a moment in time, for Time Machine or a macOS update. macOS deletes them automatically when space runs low.")
    }

    static var activityByAppNote: String {
        tr("Spotlight indexing, Time Machine and other system services run as other users, so their disk activity only shows in the totals above.")
    }

    static var latencyExplanation: String {
        tr("Latency is how long the disk takes, on average, to complete one read or write. It rises when the disk is the bottleneck, even if little data moves.")
    }

    static var containerExplanation: String {
        tr("Your startup disk is one APFS container shared by several volumes. They all draw from the same free space, so none of them has a fixed size.")
    }

    static var trendForecastNote: String {
        tr("Estimate: the recent pace extended in a straight line. A large download or cleanup changes it quickly.")
    }

    static var writesNote: String {
        tr("Writing is what wears an SSD. Apple does not publish an endurance rating for its drives, so iSensa shows the pace and the wear the drive itself reports, not a remaining lifespan.")
    }

    static var speedTestExplanation: String {
        tr("Writes a 2 GB temporary file to the selected disk and reads it back, bypassing the memory cache. The file is deleted when the test ends. Each run adds a little wear to an SSD, so run it only when you need it.")
    }

    static var onboardingNotifications: String {
        tr("iSensa can tell you when your Mac runs hot, memory is under pressure, the disk is almost full or the battery is low.")
    }

    static var soundsExplanation: String {
        tr("iSensa plays a soft sound only when an action completes or an alert needs you. It stays silent when interface sound effects are off in System Settings › Sound.")
    }

    static var energyExplanation: String {
        tr("iSensa also pauses while your Mac sleeps and slows down while the display is off. Process lists, clock speeds and Wi-Fi details are only read while a window or the menu bar panel is open.")
    }

    static var privacyStatement: String {
        tr("iSensa does not send metrics, identifiers or any other data to servers. There is no hidden telemetry. Network monitoring reads byte counters only and never inspects traffic.")
    }
}
// swiftlint:enable line_length
