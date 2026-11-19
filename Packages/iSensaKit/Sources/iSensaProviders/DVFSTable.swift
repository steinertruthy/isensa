import Foundation
import iSensaHardware

/// Frequency tables (DVFS operating points) published by the power manager in the device tree.
enum DVFSTable {
    /// Device-tree keys per cluster on Apple M1–M3 (validated on Mac15,6 / M3 Pro).
    static let efficiencyKey = "voltage-states1-sram"
    static let performanceKey = "voltage-states5-sram"
    static let gpuKey = "voltage-states9"

    /// Reads a table from `IODeviceTree:/arm-io/pmgr`. Returns MHz values in table order.
    static func read(_ key: String) -> [Double]? {
        (IORegistry.deviceTreeProperty(path: "/arm-io/pmgr", key: key) as? Data).flatMap(frequencies(from:))
    }

    /// Entries are little-endian `(frequency, voltage)` UInt32 pairs. Frequencies are Hz on
    /// M1–M3 and kHz on later chips; the unit is inferred from magnitude and validated.
    static func frequencies(from data: Data) -> [Double]? {
        let bytes = [UInt8](data)
        guard bytes.count >= 8, bytes.count % 8 == 0 else { return nil }
        let raw: [Double] = stride(from: 0, to: bytes.count, by: 8).map { offset in
            Double(bytes[offset..<offset + 4].enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * UInt32($1.offset)) })
        }
        guard let peak = raw.max(), peak > 0 else { return nil }
        let divisor: Double = peak > 100_000_000 ? 1_000_000 : 1_000
        let megahertz = raw.map { $0 / divisor }
        // Plausibility guard: a misread table must disable the feature, not show nonsense.
        guard let maximum = megahertz.max(), (300...6_000).contains(maximum) else { return nil }
        return megahertz
    }
}

/// Residency-weighted frequency from IOReport performance states. Pure, testable.
enum FrequencyCalculator {
    private static let idleStates: Set<String> = ["IDLE", "OFF", "DOWN"]

    /// DVFS table index encoded in a state name: CPU states are `V<index>P<n>`, GPU states `P<index>`.
    static func tableIndex(of stateName: String) -> Int? {
        if stateName.hasPrefix("V"), let end = stateName.firstIndex(of: "P") {
            return Int(stateName[stateName.index(after: stateName.startIndex)..<end])
        }
        if stateName.hasPrefix("P") { return Int(stateName.dropFirst()) }
        return nil
    }

    /// Combines the states of every core in a cluster. Returns `nil` frequency when any active
    /// state does not map to the table (unknown layout: report activity only).
    static func activity(
        states: [[(name: String, residency: Int64)]],
        table: [Double]?
    ) -> (averageFrequency: Double?, activeResidency: Double) {
        var total: Int64 = 0
        var active: Int64 = 0
        var weighted = 0.0
        var mappable = table != nil
        for core in states {
            for state in core where state.residency > 0 {
                total += state.residency
                guard !idleStates.contains(state.name) else { continue }
                active += state.residency
                if let table, let index = tableIndex(of: state.name), table.indices.contains(index) {
                    weighted += table[index] * Double(state.residency)
                } else {
                    mappable = false
                }
            }
        }
        let residency = total > 0 ? Double(active) / Double(total) : 0
        let frequency = mappable && active > 0 ? weighted / Double(active) : nil
        return (frequency, residency)
    }
}
