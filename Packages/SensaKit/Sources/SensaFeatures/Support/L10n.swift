import Foundation

/// Localized strings of the feature layer. Keys are English source strings; translations
/// live in `Localizable.xcstrings` (pt-BR first). `scripts/check-localizations.py` fails the
/// build when a key used here has no pt-BR translation.
enum L10n {
    static func tr(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: nil)
    }

    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }
}

/// Shorthand used throughout the views.
func tr(_ key: String) -> String { L10n.tr(key) }
func tr(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: L10n.tr(key), locale: Locale.current, arguments: arguments)
}
