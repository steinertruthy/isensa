import SwiftUI

/// Spacing scale (points). Generous, consistent rhythm on a 4-pt grid.
public enum Spacing {
    public static let xxSmall: CGFloat = 2
    public static let xSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xLarge: CGFloat = 24
    public static let xxLarge: CGFloat = 32
}

/// Corner radii, proportional to the element size.
public enum Radius {
    public static let small: CGFloat = 6
    public static let medium: CGFloat = 10
    public static let large: CGFloat = 14
    public static let xLarge: CGFloat = 20
}

/// Typographic scale built on the system font (SF Pro) so Dynamic Type and
/// accessibility settings are respected automatically.
public enum Typography {
    public static let largeTitle = Font.system(.largeTitle, design: .default).weight(.semibold)
    public static let title = Font.system(.title2).weight(.semibold)
    public static let headline = Font.system(.headline)
    public static let body = Font.system(.body)
    public static let callout = Font.system(.callout)
    public static let caption = Font.system(.caption)
    /// Large metric values. Rounded design + monospaced digits avoid jitter while updating.
    public static let metric = Font.system(.title, design: .rounded).weight(.semibold).monospacedDigit()
    public static let metricLarge = Font.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit()
    public static let metricSmall = Font.system(.title3, design: .rounded).weight(.medium).monospacedDigit()
    public static let technical = Font.system(.callout, design: .monospaced)
}

/// Motion presets. Every animation in Sensa goes through these so `Reduce Motion` is honoured in one place.
public enum Motion {
    public static let standard = Animation.spring(response: 0.45, dampingFraction: 0.86)
    public static let quick = Animation.spring(response: 0.28, dampingFraction: 0.9)
    public static let gentle = Animation.easeInOut(duration: 0.6)

    /// Returns `nil` (no animation) when the user prefers reduced motion.
    public static func adaptive(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
