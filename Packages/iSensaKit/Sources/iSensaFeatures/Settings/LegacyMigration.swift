import Foundation

/// iSensa was called Sensa (bundle `app.sensa.Sensa`) during development. On the first launch under
/// the new name, its preferences and its data folder (history) are carried over once. Nothing of
/// the old copy is deleted.
public enum LegacyMigration {
    public static let legacyDomain = "app.sensa.Sensa"
    static let legacyFolderName = "Sensa"
    static let folderName = "iSensa"
    static let doneKey = "migratedFromLegacyName"

    public static func run(
        defaults: UserDefaults = .standard, legacyDomain: String = legacyDomain,
        applicationSupport: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    ) {
        guard !defaults.bool(forKey: doneKey) else { return }
        for (key, value) in defaults.persistentDomain(forName: legacyDomain) ?? [:] {
            let renamed = renamedKey(key)
            if defaults.object(forKey: renamed) == nil { defaults.set(value, forKey: renamed) }
        }
        let manager = FileManager.default
        let old = applicationSupport.appendingPathComponent(legacyFolderName, isDirectory: true)
        let new = applicationSupport.appendingPathComponent(folderName, isDirectory: true)
        if manager.fileExists(atPath: old.path), !manager.fileExists(atPath: new.path) {
            try? manager.copyItem(at: old, to: new)
        }
        defaults.set(true, forKey: doneKey)
    }

    /// Window frames were saved under names such as `NSWindow Frame SensaMainWindow`.
    static func renamedKey(_ key: String) -> String {
        key.replacingOccurrences(of: "Frame " + legacyFolderName, with: "Frame " + folderName)
    }
}
