import Foundation

/// Semantic status shared by insights, alerts and the design system.
public enum HealthLevel: Int, Sendable, Codable, Comparable, Hashable {
    case normal = 0
    case attention = 1
    case critical = 2

    public static func < (lhs: HealthLevel, rhs: HealthLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}
