import Foundation

/// Rules for user-made curves. Whatever the user drags, a custom curve:
///
/// - never slows the fans down as the temperature rises;
/// - always ends at full speed, no later than `fullSpeedCeiling`;
/// - keeps its points apart, so the curve is a function.
///
/// The helper validates every target independently; these rules keep the *shape* safe.
public extension FanCurve {
    /// Temperatures a custom point can take.
    static let editableRange: ClosedRange<Double> = 30...98
    /// The last point — full speed — sits at or below this temperature.
    static let fullSpeedCeiling: Double = 98
    /// Minimum distance between neighbouring points.
    static let minimumPointGap: Double = 3
    /// Points snap to these increments while editing.
    static let temperatureStep: Double = 1
    static let fractionStep: Double = 0.05

    /// The point at `index` moved as close to the requested position as the rules allow.
    func moving(pointAt index: Int, celsius: Double, fraction: Double) -> FanCurve {
        guard points.indices.contains(index) else { return self }
        let isFirst = index == points.startIndex
        let isLast = index == points.index(before: points.endIndex)
        let lowest = isFirst ? Self.editableRange.lowerBound : points[index - 1].celsius + Self.minimumPointGap
        let highest = isLast ? Self.fullSpeedCeiling : points[index + 1].celsius - Self.minimumPointGap
        let slowest = isFirst ? 0 : points[index - 1].fraction
        let fastest = isLast ? 1 : points[index + 1].fraction
        guard lowest <= highest else { return self }

        let snappedCelsius = (celsius / Self.temperatureStep).rounded() * Self.temperatureStep
        let snappedFraction = (fraction / Self.fractionStep).rounded() * Self.fractionStep
        var moved = points
        moved[index] = Point(
            min(max(snappedCelsius, lowest), highest),
            isLast ? 1 : min(max(snappedFraction, slowest), fastest)
        )
        return FanCurve(points: moved, systemControlBelow: systemControlBelow == nil ? nil : moved[0].celsius)
    }

    /// Whether macOS keeps the fans below the first point (where it may stop them).
    func leavingFansToMacOSBelowFirstPoint(_ enabled: Bool) -> FanCurve {
        FanCurve(points: points, systemControlBelow: enabled ? points.first?.celsius : nil)
    }

    /// This curve with the custom-curve rules applied; falls back to Balanced when nothing usable is left.
    func enforcingSafety() -> FanCurve {
        var safe: [Point] = []
        for point in points.sorted(by: { $0.celsius < $1.celsius }) where point.celsius.isFinite && point.fraction.isFinite {
            let celsius = min(max(point.celsius, Self.editableRange.lowerBound), Self.fullSpeedCeiling)
            if let previous = safe.last, celsius - previous.celsius < Self.minimumPointGap { continue }
            safe.append(Point(celsius, max(point.fraction, safe.last?.fraction ?? 0)))
        }
        guard safe.count >= 2, let last = safe.last else { return Preset.balanced.curve }
        safe[safe.count - 1] = Point(last.celsius, 1)
        let quietBelow = systemControlBelow.flatMap { $0.isFinite ? min(max($0, Self.editableRange.lowerBound), safe[0].celsius) : nil }
        return FanCurve(points: safe, systemControlBelow: quietBelow)
    }
}
