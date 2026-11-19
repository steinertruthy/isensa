import Foundation

/// A semantic version such as `0.1.0`, `v1.2` or `1.0.0-beta.2`, ordered by the Semantic Versioning rules:
/// missing parts count as zero, and a pre-release comes before the release it leads to.
public struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let numbers: [Int]
    public let prerelease: [String]

    public init?(_ text: String) {
        var text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.first == "v" || text.first == "V" { text.removeFirst() }
        // Build metadata (`+…`) never affects ordering.
        if let plus = text.firstIndex(of: "+") { text = String(text[..<plus]) }
        let parts = text.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = parts[0].split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard !numbers.isEmpty, numbers.allSatisfy({ ($0 ?? -1) >= 0 }) else { return nil }
        self.numbers = numbers.compactMap(\.self)
        prerelease = parts.count > 1 ? parts[1].split(separator: ".").map(String.init) : []
        if parts.count > 1 && prerelease.isEmpty { return nil }
    }

    public var isPrerelease: Bool { !prerelease.isEmpty }

    public var description: String {
        numbers.map(String.init).joined(separator: ".") + (isPrerelease ? "-" + prerelease.joined(separator: ".") : "")
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    public func hash(into hasher: inout Hasher) {
        var trimmed = numbers
        while trimmed.last == 0 { trimmed.removeLast() }
        hasher.combine(trimmed)
        hasher.combine(prerelease)
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        for index in 0..<max(lhs.numbers.count, rhs.numbers.count) {
            let left = index < lhs.numbers.count ? lhs.numbers[index] : 0
            let right = index < rhs.numbers.count ? rhs.numbers[index] : 0
            if left != right { return left < right }
        }
        switch (lhs.isPrerelease, rhs.isPrerelease) {
        case (false, false), (false, true): return false
        case (true, false): return true
        case (true, true): break
        }
        for (left, right) in zip(lhs.prerelease, rhs.prerelease) where left != right {
            switch (Int(left), Int(right)) {
            case let (left?, right?): return left < right
            case (.some, nil): return true
            case (nil, .some): return false
            case (nil, nil): return left < right
            }
        }
        return lhs.prerelease.count < rhs.prerelease.count
    }
}
