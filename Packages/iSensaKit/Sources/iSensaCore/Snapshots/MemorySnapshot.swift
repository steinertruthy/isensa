import Foundation

/// System memory pressure as reported by the kernel. This — not the share of used
/// RAM — is the signal for memory health: macOS deliberately keeps RAM full of caches.
public enum MemoryPressure: Int, Sendable, Codable, Comparable {
    case normal = 1
    case warning = 2
    case critical = 4

    public static func < (lhs: MemoryPressure, rhs: MemoryPressure) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct MemorySnapshot: SnapshotFragment, Equatable {
    public let timestamp: Date
    public let total: UInt64
    /// Anonymous memory owned by apps (internal − purgeable pages).
    public let app: UInt64
    public let wired: UInt64
    /// Physical memory occupied by the compressor.
    public let compressed: UInt64
    /// File-backed and purgeable memory that can be reclaimed instantly.
    public let cached: UInt64
    public let free: UInt64
    public let swapUsed: UInt64
    public let swapTotal: UInt64
    public let pressure: MemoryPressure
    /// Kernel's "memory free percentage" (`kern.memorystatus_level`), `0...1`.
    public let availableLevel: Double?

    public init(
        timestamp: Date,
        total: UInt64,
        app: UInt64,
        wired: UInt64,
        compressed: UInt64,
        cached: UInt64,
        free: UInt64,
        swapUsed: UInt64,
        swapTotal: UInt64,
        pressure: MemoryPressure,
        availableLevel: Double?
    ) {
        self.timestamp = timestamp
        self.total = total
        self.app = app
        self.wired = wired
        self.compressed = compressed
        self.cached = cached
        self.free = free
        self.swapUsed = swapUsed
        self.swapTotal = swapTotal
        self.pressure = pressure
        self.availableLevel = availableLevel
    }

    /// Same definition as Activity Monitor's "Memory Used": app + wired + compressed.
    public var used: UInt64 { app + wired + compressed }

    public var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }

    /// `0...1`, derived from the kernel's free level. Higher means more pressure.
    public var pressureFraction: Double? { availableLevel.map { 1 - $0 } }

    public func apply(to snapshot: inout SystemSnapshot) { snapshot.memory = self }

    public var readings: [Reading] {
        let source = Provenance.system(api: "host_statistics64")
        var result = [
            Reading(metric: .memoryUsed, value: Double(used), unit: .bytes, timestamp: timestamp, provenance: source),
            Reading(metric: .swapUsed, value: Double(swapUsed), unit: .bytes, timestamp: timestamp, provenance: source)
        ]
        if let pressureFraction {
            result.append(Reading(
                metric: .memoryPressure, value: pressureFraction, unit: .fraction,
                timestamp: timestamp, provenance: .system(api: "kern.memorystatus_level")
            ))
        }
        return result
    }
}
