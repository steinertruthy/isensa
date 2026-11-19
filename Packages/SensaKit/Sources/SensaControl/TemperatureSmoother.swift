import Foundation

/// Turns a spiky reading — the hottest CPU core jumps 10 °C within seconds — into a steady control
/// input: an exponential moving average over time, so a brief spike barely moves the fans while a
/// sustained rise reaches them within seconds.
public struct TemperatureSmoother: Sendable {
    /// After this long, about 63% of a sustained change has come through.
    public static let timeConstant: TimeInterval = 8
    /// A longer gap between samples (sleep, a stall) starts over from the next reading.
    public static let maximumGap: TimeInterval = 15

    public private(set) var value: Double?
    private var lastSample: Date?
    private let timeConstant: TimeInterval

    public init(timeConstant: TimeInterval = timeConstant) {
        self.timeConstant = timeConstant
    }

    /// Feeds a reading taken at `date` and returns the smoothed value (`nil` until a valid reading
    /// arrives). A sample no newer than the last one — the controller ticks faster than sensors
    /// update — leaves the value unchanged.
    @discardableResult
    public mutating func update(_ reading: Double, at date: Date) -> Double? {
        guard reading.isFinite else { return value }
        if let value, let lastSample {
            if date <= lastSample { return value }
            let gap = date.timeIntervalSince(lastSample)
            if gap <= Self.maximumGap {
                let next = value + (1 - exp(-gap / timeConstant)) * (reading - value)
                self.value = next
                self.lastSample = date
                return next
            }
        }
        value = reading
        lastSample = date
        return reading
    }

    public mutating func reset() {
        value = nil
        lastSample = nil
    }
}
