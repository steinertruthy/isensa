import Foundation

/// Fan speed as a function of temperature. Speeds are fractions of each fan's range
/// (0 = the fan's minimum, never off; 1 = its maximum).
public struct FanCurve: Codable, Hashable, Sendable {
    public struct Point: Codable, Hashable, Sendable {
        public let celsius: Double
        public let fraction: Double

        public init(_ celsius: Double, _ fraction: Double) {
            self.celsius = celsius
            self.fraction = min(max(fraction, 0), 1)
        }
    }

    /// Sorted by temperature.
    public let points: [Point]
    /// Below this temperature control returns to macOS, which may stop the fans entirely.
    public let systemControlBelow: Double?

    public init(points: [Point], systemControlBelow: Double? = nil) {
        self.points = points.sorted { $0.celsius < $1.celsius }
        self.systemControlBelow = systemControlBelow
    }

    /// Linear interpolation between points; flat beyond the ends.
    public func fraction(at celsius: Double) -> Double {
        guard let first = points.first, let last = points.last else { return 1 }
        if celsius <= first.celsius { return first.fraction }
        if celsius >= last.celsius { return last.fraction }
        for (lower, upper) in zip(points, points.dropFirst()) where celsius <= upper.celsius {
            let position = (celsius - lower.celsius) / (upper.celsius - lower.celsius)
            return lower.fraction + position * (upper.fraction - lower.fraction)
        }
        return last.fraction
    }

    public enum Preset: String, Codable, CaseIterable, Sendable {
        case quiet, balanced, performance

        public var curve: FanCurve {
            switch self {
            case .quiet:
                FanCurve(points: [.init(65, 0), .init(80, 0.25), .init(90, 0.6), .init(95, 1)], systemControlBelow: 65)
            case .balanced:
                FanCurve(points: [.init(55, 0), .init(70, 0.3), .init(85, 0.7), .init(92, 1)], systemControlBelow: 55)
            case .performance:
                FanCurve(points: [.init(40, 0.15), .init(60, 0.45), .init(75, 0.8), .init(85, 1)])
            }
        }
    }
}

/// What the user asked for. Persisted; `automatic` is the default and the safe fallback.
public enum FanMode: Codable, Hashable, Sendable {
    /// macOS controls the fans.
    case automatic
    /// Every fan at the same position of its range.
    case fixed(fraction: Double)
    /// Speed follows the CPU temperature.
    case curve(FanCurve.Preset)

    public var isManual: Bool { self != .automatic }
}
