import Foundation

/// Languages Sensa is translated into. `.system` follows macOS' language order.
public enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case english = "en"
    case portugueseBrazil = "pt-BR"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"

    public var id: String { rawValue }

    /// Each language names itself (as in System Settings), so anyone can find their own.
    public var nativeName: String {
        guard self != .system else { return tr("System language") }
        let locale = Locale(identifier: rawValue)
        return locale.localizedString(forIdentifier: rawValue)?.capitalized(with: locale) ?? rawValue
    }

    /// Localizations shipped in the bundle (used by the localization check).
    public static var translated: [AppLanguage] { allCases.filter { $0 != .system } }
}
