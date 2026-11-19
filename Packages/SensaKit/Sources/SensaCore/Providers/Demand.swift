import Foundation

/// How much the user is currently looking at live data. Drives sampling intervals.
public enum Demand: Int, Sendable, Comparable, CaseIterable {
    /// Nothing visible that needs live data (e.g. menu bar indicators hidden, screen locked).
    case idle
    /// Only menu bar indicators are visible.
    case background
    /// Popover or main window visible.
    case interactive

    public static func < (lhs: Demand, rhs: Demand) -> Bool { lhs.rawValue < rhs.rawValue }
}
