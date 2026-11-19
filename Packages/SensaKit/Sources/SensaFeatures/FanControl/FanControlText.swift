// swiftlint:disable line_length
// Fan control prose lives here so the card stays readable and translators find it in one place.

import SensaControl

/// User-facing wording for fan control states.
enum FanControlText {
    static func modeTitle(_ kind: FanModeKind) -> String {
        switch kind {
        case .automatic: tr("Automatic")
        case .fixed: tr("Fixed speed")
        case .curve: tr("Curve")
        }
    }

    static func presetTitle(_ preset: FanCurve.Preset) -> String {
        switch preset {
        case .quiet: tr("Quiet")
        case .balanced: tr("Balanced")
        case .performance: tr("Performance")
        }
    }

    static func presetDescription(_ preset: FanCurve.Preset, formatter: MetricFormatter) -> String {
        let curve = preset.curve
        let quietBelow = formatter.temperature(curve.systemControlBelow ?? 0)
        let fullSpeed = formatter.temperature(curve.points.first { $0.fraction >= 1 }?.celsius ?? 100)
        return switch preset {
        case .quiet: tr("Leaves the fans to macOS below %@, then speeds up gently.", quietBelow)
        case .balanced: tr("Leaves the fans to macOS below %@, then follows the temperature.", quietBelow)
        case .performance: tr("Keeps the fans running and reaches full speed at %@.", fullSpeed)
        }
    }

    static func systemReason(_ reason: SystemControlReason) -> String {
        switch reason {
        case .userChoice: tr("macOS is controlling the fans.")
        case .coolEnough: tr("Cool enough: macOS is controlling the fans, which may stop.")
        case .noTemperature: tr("No recent temperature reading, so macOS is controlling the fans.")
        case .thermalPressure: tr("Your Mac is under thermal pressure, so macOS is controlling the fans.")
        case .tooHotForFixedSpeed: tr("Too hot for a fixed speed below maximum, so macOS is controlling the fans.")
        case .noLimits: tr("Fan limits are unavailable, so macOS is controlling the fans.")
        }
    }

    static func problem(_ problem: FanControlProblem) -> String {
        switch problem {
        case .notApplied: tr("The fan controller did not accept the change, so macOS keeps control of the fans.")
        case .installFailed: tr("The helper could not be installed.")
        case .removeFailed: tr("The helper could not be removed.")
        case .restoreFailed: tr("Returning the fans to automatic reported a problem. If they keep running fast, restart your Mac.")
        }
    }

    static var safety: String {
        tr("Sensa never stops a fan or goes beyond its limits. If Sensa quits or stops responding, or your Mac gets too hot, the fans return to automatic within 10 seconds.")
    }

    static var helperExplanation: String {
        tr("Changing fan speeds needs a small helper that runs with administrator rights. macOS asks for your password to install it. Monitoring works without it.")
    }

    static var unsignedNote: String {
        tr("This copy of Sensa is not signed with an Apple Developer ID, so the helper is installed with a password prompt instead of System Settings. Rebuilding Sensa requires updating the helper.")
    }
}

// swiftlint:enable line_length

/// Mode choices shown in the picker (the fixed speed and preset are kept separately).
enum FanModeKind: String, CaseIterable, Identifiable {
    case automatic, fixed, curve

    var id: String { rawValue }

    init(_ mode: FanMode) {
        switch mode {
        case .automatic: self = .automatic
        case .fixed: self = .fixed
        case .curve: self = .curve
        }
    }
}
