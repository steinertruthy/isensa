import Foundation

/// What iSensa may move to the Trash. Checked before every removal, whatever screen asked for it.
///
/// Allowed: things inside the home folder and apps in the Applications folders. Refused: the
/// folders macOS and the person rely on (the home folder itself, Documents, Library and its
/// top-level folders…), configuration files, parts of an app, Apple's protected apps, iSensa
/// itself, apps that are open, and data other apps manage (Photos and Music libraries, cloud storage).
public struct RemovalPolicy: Sendable {
    public enum Refusal: Sendable, Equatable {
        case outsideHomeAndApplications
        case essentialFolder
        case configuration
        case insideAnApp
        case systemApp
        case iSensa
        case open(String)
        case managedByAnotherApp
    }

    public let home: URL
    public let applicationFolders: [URL]
    public let ownBundle: URL
    /// Bundle identifiers of apps running now.
    public let runningApps: [String: String]

    public init(home: URL, applicationFolders: [URL], ownBundle: URL, runningApps: [String: String]) {
        self.home = home.standardizedFileURL
        self.applicationFolders = applicationFolders.map(\.standardizedFileURL)
        self.ownBundle = ownBundle.standardizedFileURL
        self.runningApps = runningApps
    }

    private static let essentialHomeFolders = [
        "Applications", "Desktop", "Documents", "Downloads", "Library", "Movies", "Music", "Pictures", "Public", ".Trash"
    ]
    private static let protectedLibraryFolders = ["Keychains", "Mail", "Messages", "Mobile Documents", "CloudStorage", "Accounts", "Cookies"]
    private static let managedPackages = ["photoslibrary", "musiclibrary", "tvlibrary", "photolibrary", "aplibrary"]

    /// `nil` when the item may go to the Trash; otherwise why not.
    public func refusal(for url: URL, bundleIdentifier: String? = nil) -> Refusal? {
        let path = url.standardizedFileURL.path
        // Where a symbolic link really points: Safari in /Applications, for one, lives in a sealed system volume.
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath().path
        let components = url.standardizedFileURL.pathComponents
        if path == ownBundle.path || path.hasPrefix(ownBundle.path + "/") { return .iSensa }
        if components.dropLast().contains(where: { $0.hasSuffix(".app") }) { return .insideAnApp }
        if applicationFolders.contains(where: { path.hasPrefix($0.path + "/") }) {
            if bundleIdentifier == "com.apple.Safari" || resolved.hasPrefix("/System/") { return .systemApp }
            if let running = runningName(url: url, bundleIdentifier: bundleIdentifier) { return .open(running) }
            return nil
        }
        let homePath = home.path
        guard path.hasPrefix(homePath + "/") else { return .outsideHomeAndApplications }
        if let refusal = Self.homeRefusal(path.dropFirst(homePath.count + 1).split(separator: "/").map(String.init)) { return refusal }
        if let ext = components.last.map({ ($0 as NSString).pathExtension.lowercased() }), Self.managedPackages.contains(ext) {
            return .managedByAnotherApp
        }
        if let running = runningName(url: url, bundleIdentifier: bundleIdentifier) { return .open(running) }
        return nil
    }

    /// Folders in the home folder that stay, whatever is inside them.
    private static func homeRefusal(_ relative: [String]) -> Refusal? {
        guard let first = relative.first else { return .essentialFolder }
        if relative.count == 1 {
            if essentialHomeFolders.contains(first) { return .essentialFolder }
            if first.hasPrefix(".") { return .configuration }
        }
        guard first == "Library" else { return nil }
        if relative.count == 2 { return .essentialFolder }
        if protectedLibraryFolders.contains(relative[1]) { return .managedByAnotherApp }
        if relative.count >= 3, relative[1] == "Preferences", !(relative.last?.hasSuffix(".plist") ?? false) { return .configuration }
        return nil
    }

    /// An app that is open, matched by its bundle identifier or by a Library folder named after it.
    private func runningName(url: URL, bundleIdentifier: String?) -> String? {
        if let bundleIdentifier, let name = runningApps[bundleIdentifier] { return name }
        // "Caches/com.example.App", "Preferences/com.example.App.plist", "Application Support/Example".
        let last = url.lastPathComponent
        let trimmed = ["plist", "savedState", "binarycookies", "app"].contains(url.pathExtension) ? url.deletingPathExtension().lastPathComponent : last
        return runningApps[last] ?? runningApps[trimmed]
    }
}
