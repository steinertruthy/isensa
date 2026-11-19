import Foundation

/// NVMe SMART health log, exactly as reported by the drive. iSensa never extrapolates
/// remaining lifetime beyond the drive's own `percentageUsed` estimate.
public struct SSDHealth: Sendable, Equatable {
    public let criticalWarning: UInt8
    public let temperature: Double?
    public let availableSpare: Int
    public let availableSpareThreshold: Int
    /// Drive's own estimate of endurance consumed, `0...255` % (may exceed 100).
    public let percentageUsed: Int
    public let bytesRead: UInt64
    public let bytesWritten: UInt64
    public let powerOnHours: UInt64
    public let powerCycles: UInt64
    public let unsafeShutdowns: UInt64
    public let mediaErrors: UInt64

    public init(
        criticalWarning: UInt8, temperature: Double?, availableSpare: Int, availableSpareThreshold: Int, percentageUsed: Int,
        bytesRead: UInt64, bytesWritten: UInt64, powerOnHours: UInt64, powerCycles: UInt64, unsafeShutdowns: UInt64, mediaErrors: UInt64
    ) {
        self.criticalWarning = criticalWarning
        self.temperature = temperature
        self.availableSpare = availableSpare
        self.availableSpareThreshold = availableSpareThreshold
        self.percentageUsed = percentageUsed
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
        self.powerOnHours = powerOnHours
        self.powerCycles = powerCycles
        self.unsafeShutdowns = unsafeShutdowns
        self.mediaErrors = mediaErrors
    }

    /// The drive itself flags a problem (NVMe critical warning bits or spare below threshold).
    public var reportsCriticalCondition: Bool {
        criticalWarning != 0 || availableSpare < availableSpareThreshold
    }
}
