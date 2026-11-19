import SensaCore
import SensaInsights

// swiftlint:disable line_length
enum SpaceText {
    static func refusal(_ refusal: RemovalPolicy.Refusal) -> String {
        switch refusal {
        case .outsideHomeAndApplications: tr("Sensa only removes items in your home folder and apps in the Applications folders.")
        case .essentialFolder: tr("macOS and your apps rely on this folder.")
        case .configuration: tr("This holds settings that apps and macOS rely on.")
        case .insideAnApp: tr("This is part of an app. Remove the whole app instead.")
        case .systemApp: tr("This app is part of macOS.")
        case .sensa: tr("This is Sensa itself.")
        case let .open(name): tr("%@ is open. Quit it first.", name)
        case .managedByAnotherApp: tr("Another app manages this. Clean it up from that app.")
        }
    }

    static func category(_ kind: SpaceCategory.Kind) -> String {
        switch kind {
        case .apps: tr("Apps")
        case .documents: tr("Documents and Desktop")
        case .downloads: tr("Downloads")
        case .media: tr("Photos, music and movies")
        case .developer: tr("Developer tools")
        case .appData: tr("App data")
        case .caches: tr("Caches")
        case .mailAndMessages: tr("Mail and Messages")
        case .trash: tr("Trash")
        case .other: tr("Other files")
        }
    }

    static func suggestionTitle(_ kind: CleanupSuggestion.Kind) -> String {
        switch kind {
        case .installers: tr("Installers you already used")
        case .staleDownloads: tr("Large downloads you haven't touched in 90 days")
        case .derivedData: tr("Xcode build files")
        case .deviceSupport: tr("Xcode device support files")
        case .largeCaches: tr("Large caches")
        case .unusedApps: tr("Apps not opened in 6 months")
        case .simulators: tr("Simulators")
        case .docker: tr("Docker data")
        case .iPhoneBackups: tr("iPhone and iPad backups")
        case .trash: tr("Items in the Trash")
        }
    }

    static func suggestionDetail(_ kind: CleanupSuggestion.Kind) -> String {
        switch kind {
        case .installers: tr("Disk images and installer packages in Downloads and on the Desktop. Once an app is installed, its installer is no longer needed.")
        case .staleDownloads: tr("Files over 100 MB in Downloads that have not changed in 90 days. Review them before removing.")
        case .derivedData: tr("Xcode recreates these the next time you build. Projects build more slowly the first time.")
        case .deviceSupport: tr("Debugging symbols for devices you connected to Xcode. Xcode downloads them again when needed.")
        case .largeCaches: tr("Apps rebuild their caches when needed. Caches of open apps are kept.")
        case .unusedApps: tr("Removing an app also removes the support files it left in your Library, after you review them.")
        case .simulators: tr("Delete simulators you no longer use in Xcode › Settings › Components, or run “xcrun simctl delete unavailable” in Terminal.")
        case .docker: tr("Docker keeps images and volumes in one disk file. Free it in Docker Desktop › Troubleshoot › Clean / Purge data, or with “docker system prune”.")
        case .iPhoneBackups: tr("Manage backups in Finder: select your device, then Manage Backups. Delete only the ones you no longer need.")
        case .trash: tr("Items in the Trash still take space until you empty it in Finder.")
        }
    }

    static var fullDiskAccessNote: String {
        tr("Some folders are protected by macOS, so their size is not counted. To include them, give Sensa Full Disk Access in System Settings › Privacy & Security. Sensa only reads sizes, never contents.")
    }

    static var permissionsNote: String {
        tr("Sensa reads only the names and sizes of files in your home folder and the Applications folders. macOS may ask before Sensa looks into Desktop, Documents, Downloads or other apps' data.")
    }

    static var trashNote: String {
        tr("Items go to the Trash. You can put them back until you empty it.")
    }

    static var cloudNote: String {
        tr("iCloud Drive and other cloud folders are not analyzed: their apps decide which files stay on this Mac.")
    }
}
// swiftlint:enable line_length
