import Foundation

/// Speed range a fan supports, read from the hardware at the moment it is used.
public struct FanLimits: Codable, Hashable, Sendable {
    public let index: Int
    public let minimumRPM: Double
    public let maximumRPM: Double

    public init(index: Int, minimumRPM: Double, maximumRPM: Double) {
        self.index = index
        self.minimumRPM = minimumRPM
        self.maximumRPM = maximumRPM
    }

    /// Plausible limits only: a positive minimum below a maximum no Mac fan exceeds.
    public var isValid: Bool {
        minimumRPM.isFinite && maximumRPM.isFinite && minimumRPM > 0 && maximumRPM > minimumRPM && maximumRPM <= 20_000
    }

    /// Speed at `fraction` of the range, where 0 is the fan's minimum (never zero) and 1 its maximum.
    public func rpm(atFraction fraction: Double) -> Double {
        minimumRPM + min(max(fraction, 0), 1) * (maximumRPM - minimumRPM)
    }
}

/// A requested speed for one fan.
public struct FanTarget: Codable, Hashable, Sendable {
    public let index: Int
    public let rpm: Double

    public init(index: Int, rpm: Double) {
        self.index = index
        self.rpm = rpm
    }
}

public enum FanCommandError: Error, Equatable, Sendable, CustomStringConvertible {
    case empty
    case unknownFan(Int)
    case duplicateFan(Int)
    case invalidLimits(Int)
    case invalidSpeed(Int)

    public var description: String {
        switch self {
        case .empty: "No fan targets"
        case let .unknownFan(fan): "Unknown fan \(fan)"
        case let .duplicateFan(fan): "Fan \(fan) listed twice"
        case let .invalidLimits(fan): "Implausible limits for fan \(fan)"
        case let .invalidSpeed(fan): "Invalid speed for fan \(fan)"
        }
    }
}

/// Validates a request against the limits read from the hardware. Used by the app *and*
/// again by the privileged helper, which never trusts its client.
public enum FanCommandValidator {
    /// Returns the targets clamped into each fan's supported range.
    public static func validate(_ targets: [FanTarget], limits: [FanLimits]) throws -> [FanTarget] {
        guard !targets.isEmpty else { throw FanCommandError.empty }
        var seen = Set<Int>()
        return try targets.map { target in
            guard seen.insert(target.index).inserted else { throw FanCommandError.duplicateFan(target.index) }
            guard let limit = limits.first(where: { $0.index == target.index }) else { throw FanCommandError.unknownFan(target.index) }
            guard limit.isValid else { throw FanCommandError.invalidLimits(target.index) }
            guard target.rpm.isFinite, target.rpm > 0 else { throw FanCommandError.invalidSpeed(target.index) }
            return FanTarget(index: target.index, rpm: min(max(target.rpm, limit.minimumRPM), limit.maximumRPM))
        }
    }
}
