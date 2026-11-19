import Foundation

/// Processor family, parsed from the brand string reported by the system.
public enum ChipFamily: Sendable, Hashable, Codable {
    case appleSilicon(generation: Int, tier: AppleSiliconTier)
    case intel
    case unknown

    /// Parses strings such as `"Apple M3 Pro"`, `"Apple M1"`, `"Apple M4 Max"`,
    /// `"Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz"`.
    public init(brandString: String) {
        let trimmed = brandString.trimmingCharacters(in: .whitespaces)
        if trimmed.localizedCaseInsensitiveContains("intel") {
            self = .intel
            return
        }
        let words = trimmed.split(separator: " ").map(String.init)
        guard let chipIndex = words.firstIndex(where: { $0.hasPrefix("M") && Int($0.dropFirst()) != nil }),
              let generation = Int(words[chipIndex].dropFirst()) else {
            self = .unknown
            return
        }
        let tierWord = words.indices.contains(chipIndex + 1) ? words[chipIndex + 1] : ""
        self = .appleSilicon(generation: generation, tier: AppleSiliconTier(word: tierWord))
    }

    public var isAppleSilicon: Bool {
        if case .appleSilicon = self { return true }
        return false
    }
}

public enum AppleSiliconTier: String, Sendable, Hashable, Codable {
    case base, pro, max, ultra

    init(word: String) {
        self = AppleSiliconTier(rawValue: word.lowercased()) ?? .base
    }
}
