import SwiftUI

/// Spacing scale (points) on a 4-pt grid.
public enum Spacing {
    public static let xxSmall: CGFloat = 2
    public static let xSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xLarge: CGFloat = 24
    public static let xxLarge: CGFloat = 32
    public static let section: CGFloat = 28
}

/// Corner radii, proportional to the element they round.
public enum Radius {
    public static let small: CGFloat = 6
    public static let medium: CGFloat = 9
    public static let large: CGFloat = 12
    public static let xLarge: CGFloat = 18
}

/// Two voices of SF Pro. Text styles stay semantic so accessibility text sizes apply.
public enum Typography {
    // Text voice
    public static let largeTitle = Font.system(size: 26, weight: .semibold)
    public static let title = Font.system(.title3).weight(.semibold)
    public static let headline = Font.system(.headline)
    public static let body = Font.system(.body)
    public static let callout = Font.system(.callout)
    public static let caption = Font.system(.caption)
    public static let technical = Font.system(.callout, design: .monospaced)

    // Number voice: rounded, tabular, never jittering while values update.
    public static func number(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    public static let metric = number(26)
    public static let metricLarge = number(46)
    public static let metricSmall = number(17, weight: .medium)
}

/// Motion presets. Views animate through `.sensaAnimation(_:value:)`, which applies the user's
/// preference and the system's Reduce Motion setting in one place.
public enum Motion {
    public static let standard = Animation.spring(response: 0.45, dampingFraction: 0.86)
    public static let quick = Animation.spring(response: 0.28, dampingFraction: 0.9)
    public static let gentle = Animation.easeInOut(duration: 0.6)
    /// Moving between screens: quick to settle so navigation never feels slow.
    public static let screen = Animation.spring(response: 0.36, dampingFraction: 0.9)
    /// Showing and hiding the sidebar.
    public static let sidebar = Animation.spring(response: 0.42, dampingFraction: 0.88)
    /// Live values (gauges, meters, bars) easing to a new sample. Short and non-springy: samples arrive
    /// every second, and a spring that takes most of that second keeps the screen redrawing continuously.
    public static let update = Animation.easeOut(duration: 0.3)
    /// Headline digits rolling to a new value: short, so a once-a-second refresh stays cheap.
    public static let digits = Animation.easeOut(duration: 0.22)
    /// Gauges and meters filling to their value when a screen opens, just after the screen settles.
    public static let reveal = Animation.spring(response: 0.8, dampingFraction: 0.9).delay(0.06)
    /// The outgoing screen leaves faster than the new one arrives, so the two never read over each other.
    public static let exit = Animation.easeOut(duration: 0.12)
    /// Used instead of movement when motion is reduced: a short crossfade-like ease.
    public static let reduced = Animation.easeInOut(duration: 0.15)

    /// Resolves an animation for the effective motion level (`nil` = no animation).
    public static func resolve(_ animation: Animation, preference: MotionPreference, reduceMotion: Bool) -> Animation? {
        switch effective(preference, reduceMotion: reduceMotion) {
        case .full: animation
        case .reduced: reduced
        case .off: nil
        }
    }

    /// Applies `change` with `animation` at the effective motion level — instantly when motion is off.
    @MainActor
    public static func perform(_ animation: Animation, preference: MotionPreference, reduceMotion: Bool, _ change: () -> Void) {
        if let resolved = resolve(animation, preference: preference, reduceMotion: reduceMotion) {
            withAnimation(resolved, change)
        } else {
            change()
        }
    }

    public static func effective(_ preference: MotionPreference, reduceMotion: Bool) -> MotionPreference {
        if preference == .off { return .off }
        return reduceMotion ? .reduced : preference
    }
}

/// How much the interface moves. The system's Reduce Motion always lowers `.full` to `.reduced`.
public enum MotionPreference: String, CaseIterable, Codable, Sendable {
    case full, reduced, off
}

public extension EnvironmentValues {
    @Entry var sensaMotion: MotionPreference = .full
}

private struct SensaAnimation<Value: Equatable>: ViewModifier {
    let animation: Animation
    let value: Value
    @Environment(\.sensaMotion) private var preference
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(Motion.resolve(animation, preference: preference, reduceMotion: reduceMotion), value: value)
    }
}

public extension AnyTransition {
    /// How a screen or settings pane enters: it fades in while rising a few points into place.
    /// Reduced motion keeps only the fade; with motion off the change is instant.
    static func sensaScreen(_ level: MotionPreference) -> AnyTransition {
        switch level {
        case .full:
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 10)).combined(with: .scale(scale: 0.995, anchor: .top)),
                removal: .opacity.animation(Motion.exit)
            )
        case .reduced: .asymmetric(insertion: .opacity, removal: .opacity.animation(Motion.exit))
        case .off: .identity
        }
    }
}

/// Swaps content identified by `id` with the screen transition, animated per the motion preference.
private struct ScreenTransition<ID: Hashable>: ViewModifier {
    let id: ID
    @Environment(\.sensaMotion) private var preference
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        ZStack {
            content
                .id(id)
                .transition(.sensaScreen(Motion.effective(preference, reduceMotion: reduceMotion)))
        }
        .animation(Motion.resolve(Motion.screen, preference: preference, reduceMotion: reduceMotion), value: id)
    }
}

/// Fills a gauge or meter from zero the first time it appears. `revealed` gates the drawn value.
private struct RevealOnAppear: ViewModifier {
    @Binding var revealed: Bool
    @Environment(\.sensaMotion) private var preference
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.onAppear {
            guard !revealed else { return }
            Motion.perform(Motion.reveal, preference: preference, reduceMotion: reduceMotion) { revealed = true }
        }
    }
}

public extension View {
    /// Sets `revealed` on first appearance, animated with `Motion.reveal` (instantly when motion is off).
    func revealOnAppear(_ revealed: Binding<Bool>) -> some View {
        modifier(RevealOnAppear(revealed: revealed))
    }

    /// Replaces the content with a screen transition whenever `id` changes (navigation, settings panes).
    func sensaScreenTransition<ID: Hashable>(id: ID) -> some View {
        modifier(ScreenTransition(id: id))
    }

    /// Animates changes of `value`, honouring the app's motion preference and Reduce Motion.
    func sensaAnimation<Value: Equatable>(_ animation: Animation = Motion.standard, value: Value) -> some View {
        modifier(SensaAnimation(animation: animation, value: value))
    }
}
