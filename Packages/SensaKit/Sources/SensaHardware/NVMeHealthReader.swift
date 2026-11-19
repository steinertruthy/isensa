import CSensaHardware

/// SMART health log of the internal NVMe SSD (public `IONVMeSMARTInterface`).
public struct NVMeHealthLog: Sendable, Equatable {
    public var criticalWarning: UInt8
    public var temperatureCelsius: Double?
    /// Remaining spare capacity, `0...100` %.
    public var availableSpare: Int
    public var availableSpareThreshold: Int
    /// Vendor estimate of life used, `0...255` % (can exceed 100).
    public var percentageUsed: Int
    /// Bytes (NVMe data units are 1000 × 512 bytes).
    public var bytesRead: UInt64
    public var bytesWritten: UInt64
    public var powerCycles: UInt64
    public var powerOnHours: UInt64
    public var unsafeShutdowns: UInt64
    public var mediaErrors: UInt64

    public init(
        criticalWarning: UInt8, temperatureCelsius: Double?, availableSpare: Int, availableSpareThreshold: Int,
        percentageUsed: Int, bytesRead: UInt64, bytesWritten: UInt64, powerCycles: UInt64,
        powerOnHours: UInt64, unsafeShutdowns: UInt64, mediaErrors: UInt64
    ) {
        self.criticalWarning = criticalWarning
        self.temperatureCelsius = temperatureCelsius
        self.availableSpare = availableSpare
        self.availableSpareThreshold = availableSpareThreshold
        self.percentageUsed = percentageUsed
        self.bytesRead = bytesRead
        self.bytesWritten = bytesWritten
        self.powerCycles = powerCycles
        self.powerOnHours = powerOnHours
        self.unsafeShutdowns = unsafeShutdowns
        self.mediaErrors = mediaErrors
    }
}

public enum NVMeHealthReader {
    static let bytesPerDataUnit: UInt64 = 512_000

    public static func read() -> NVMeHealthLog? {
        var raw = SensaNVMeHealth()
        guard sensa_nvme_read_health(&raw) == 0 else { return nil }
        return log(from: raw)
    }

    static func log(from raw: SensaNVMeHealth) -> NVMeHealthLog {
        NVMeHealthLog(
            criticalWarning: raw.criticalWarning,
            temperatureCelsius: raw.temperatureKelvin > 0 ? Double(raw.temperatureKelvin) - 273.15 : nil,
            availableSpare: Int(raw.availableSpare),
            availableSpareThreshold: Int(raw.availableSpareThreshold),
            percentageUsed: Int(raw.percentageUsed),
            bytesRead: raw.dataUnitsRead.multipliedReportingOverflow(by: bytesPerDataUnit).partialValue,
            bytesWritten: raw.dataUnitsWritten.multipliedReportingOverflow(by: bytesPerDataUnit).partialValue,
            powerCycles: raw.powerCycles,
            powerOnHours: raw.powerOnHours,
            unsafeShutdowns: raw.unsafeShutdowns,
            mediaErrors: raw.mediaErrors
        )
    }
}
