import Foundation

/// ⚠️ PRIVATE INTERFACE — the only code in Sensa that writes to the SMC. Used exclusively by the
/// privileged helper (writes require root).
///
/// It can write exactly three kinds of keys: `Ftst` (the Apple Silicon unlock for manual fan
/// control), `F<n>Md` (a fan's mode) and `F<n>Tg` (its target speed), and only for fans the SMC
/// reports in `FNum`. Speeds are not validated here — `FanSafetyController` does that against
/// limits read immediately before — but every mode change is read back to confirm it took effect.
///
/// On M3 and later, macOS' thermal manager holds the fans in system mode (3) and the firmware answers
/// a manual-mode write with 0x82 until `Ftst` is set and the manager lets go, a few seconds later.
/// Writes are kept to a minimum: some Apple silicon firmware reportedly accepts a limited number of
/// fan writes per boot, so unchanged values are never written again.
public final class SMCFanWriter {
    /// Mode value meaning "manual/forced" on every SMC generation documented by the community.
    public static let manualMode: UInt8 = 1

    private let smc: SMCConnection
    public let fanCount: Int
    private let hasTestUnlock: Bool
    private var lastTargets: [Int: Double] = [:]
    /// Writes accepted by the firmware since the helper started (diagnostics).
    public private(set) var writeCount = 0

    public init() throws {
        smc = try SMCConnection()
        fanCount = min(Int(smc.number("FNum") ?? 0), 10)
        hasTestUnlock = smc.number("Ftst") != nil
    }

    public func minimumRPM(fan: Int) -> Double? { smc.number(key(fan, "Mn")) }
    public func maximumRPM(fan: Int) -> Double? { smc.number(key(fan, "Mx")) }

    public func mode(fan: Int) -> UInt8? {
        smc.number(key(fan, "Md")).map { UInt8(clamping: Int($0)) }
    }

    /// Switches the fan to manual (unlocking it where the firmware requires) and sets its target.
    /// May take several seconds the first time on M3 and later.
    public func setManual(fan: Int, rpm: Double, unlockTimeout: TimeInterval = 12) throws {
        guard (0..<fanCount).contains(fan) else { throw SMCError.keyNotWritable("F\(fan)Md") }
        if mode(fan: fan) != Self.manualMode {
            try enterManualMode(fan: fan, timeout: unlockTimeout)
            lastTargets[fan] = nil
        }
        // A target is only written when it changes.
        if let last = lastTargets[fan], abs(last - rpm) < 1 { return }
        try write(key(fan, "Tg"), value: rpm)
        lastTargets[fan] = rpm
    }

    /// Writes `mode` (the value the fan reported before Sensa touched it, or 0) back to the fan.
    public func setMode(fan: Int, mode value: UInt8) throws {
        guard (0..<fanCount).contains(fan) else { throw SMCError.keyNotWritable("F\(fan)Md") }
        lastTargets[fan] = nil
        if mode(fan: fan) == value { return }
        try write(key(fan, "Md"), value: Double(value))
    }

    /// Ends the Apple Silicon test mode, returning fan control to the firmware.
    public func lockManualControl() throws {
        if hasTestUnlock, smc.number("Ftst") != 0 { try write("Ftst", value: 0) }
    }

    /// Direct write first (older generations); on 0x82, set `Ftst` and retry once a second until the
    /// thermal manager releases the fan.
    private func enterManualMode(fan: Int, timeout: TimeInterval) throws {
        let modeKey = key(fan, "Md")
        if try attemptManual(modeKey, fan: fan) { return }
        guard hasTestUnlock else { throw SMCError.manualModeRefused(modeKey.description) }
        if smc.number("Ftst") != 1 { try write("Ftst", value: 1) }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            Thread.sleep(forTimeInterval: 1)
            if try attemptManual(modeKey, fan: fan) { return }
        }
        throw SMCError.manualModeRefused(modeKey.description)
    }

    /// `true` once the fan reads back as manual; `false` while the firmware answers 0x82.
    private func attemptManual(_ modeKey: SMCKey, fan: Int) throws -> Bool {
        do {
            try write(modeKey, value: Double(Self.manualMode))
        } catch SMCError.firmwareError(SMCError.badCommand) {
            return false
        }
        for _ in 0..<10 {
            if mode(fan: fan) == Self.manualMode { return true }
            usleep(50_000)
        }
        return false
    }

    // MARK: - Whitelisted writes

    private func key(_ fan: Int, _ suffix: String) -> SMCKey {
        SMCKey("F\(fan)\(suffix)") ?? "F0Md"
    }

    private func isWritable(_ key: SMCKey) -> Bool {
        let name = key.description
        if name == "Ftst" { return true }
        let characters = Array(name)
        guard characters.count == 4, characters[0] == "F", let fan = characters[1].wholeNumberValue, fan < fanCount else { return false }
        return ["Md", "Tg"].contains(String(characters[2...]))
    }

    private func write(_ key: SMCKey, value: Double) throws {
        guard isWritable(key) else { throw SMCError.keyNotWritable(key.description) }
        let type = try smc.dataType(of: key)
        let bytes: [UInt8]
        switch type {
        case "ui8 ", "flag":
            bytes = [UInt8(clamping: Int(value.rounded()))]
        case "flt ":
            // Little-endian IEEE-754, as the Apple Silicon SMC stores it.
            bytes = withUnsafeBytes(of: Float(value).bitPattern.littleEndian, Array.init)
        case "fpe2":
            // Intel: unsigned 14.2 fixed point, big-endian.
            let raw = UInt16(clamping: Int((value * 4).rounded()))
            bytes = [UInt8(raw >> 8), UInt8(raw & 0xFF)]
        default:
            throw SMCError.keyNotWritable("\(key.description) (\(type))")
        }
        try smc.write(key, bytes: bytes)
        writeCount += 1
    }
}
