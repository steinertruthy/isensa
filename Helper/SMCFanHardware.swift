import Foundation
import SensaControl
import SensaPrivateAPI

/// `FanHardware` on the real SMC. Remembers each fan's automatic mode value as found when the
/// helper started (3 on M3-generation Macs, 0 on older ones) and writes it back on restore.
final class SMCFanHardware: FanHardware {
    private let writer: SMCFanWriter
    private var automaticModes: [Int: UInt8] = [:]

    init(writer: SMCFanWriter) {
        self.writer = writer
        for fan in 0..<writer.fanCount {
            // A fan already in manual mode (crash, another tool) has no trustworthy baseline: use 0.
            let mode = writer.mode(fan: fan)
            automaticModes[fan] = mode == SMCFanWriter.manualMode ? 0 : (mode ?? 0)
        }
    }

    var writeCount: Int { writer.writeCount }

    func limits() throws -> [FanLimits] {
        (0..<writer.fanCount).compactMap { fan in
            guard let minimum = writer.minimumRPM(fan: fan), let maximum = writer.maximumRPM(fan: fan) else { return nil }
            return FanLimits(index: fan, minimumRPM: minimum, maximumRPM: maximum)
        }
    }

    func setManual(_ targets: [FanTarget]) throws {
        for target in targets { try writer.setManual(fan: target.index, rpm: target.rpm) }
    }

    /// How long the firmware may take to reclaim the fans after `Ftst` is cleared.
    static let handoverTimeout: TimeInterval = 10

    /// Hands the fans back to the firmware:
    /// 1. write each fan's original mode — older generations need this; on M3 and later the firmware
    ///    answers 0x82, which is expected;
    /// 2. clear `Ftst`, after which macOS' thermal manager reclaims the fans (mode 3) on its own;
    /// 3. confirm by reading back, allowing a few seconds for that handover.
    func restoreAutomatic() throws {
        var failures: [String] = []
        for fan in 0..<writer.fanCount where writer.mode(fan: fan) == SMCFanWriter.manualMode {
            do {
                try writer.setMode(fan: fan, mode: automaticModes[fan] ?? 0)
            } catch SMCError.firmwareError(SMCError.badCommand) {
                // Expected on M3 and later: the thermal manager takes over once Ftst is cleared.
            } catch {
                failures.append("F\(fan)Md: \(error)")
            }
        }
        do { try writer.lockManualControl() } catch { failures.append("Ftst: \(error)") }
        let deadline = Date().addingTimeInterval(Self.handoverTimeout)
        var stillManual = manualFans()
        while !stillManual.isEmpty, Date() < deadline {
            usleep(250_000)
            stillManual = manualFans()
        }
        guard !stillManual.isEmpty else { return }
        failures.append("fans still in manual mode after \(Int(Self.handoverTimeout)) s: \(stillManual)")
        throw FanControlFailure(failures.joined(separator: "; "))
    }

    private func manualFans() -> [Int] {
        (0..<writer.fanCount).filter { writer.mode(fan: $0) == SMCFanWriter.manualMode }
    }
}

/// Used when the SMC cannot be opened: every write fails, so control always stays with macOS.
final class UnavailableFanHardware: FanHardware {
    let reason: String
    let writeCount = 0
    init(reason: String) { self.reason = reason }
    func limits() throws -> [FanLimits] { throw FanControlFailure(reason) }
    func setManual(_ targets: [FanTarget]) throws { throw FanControlFailure(reason) }
    func restoreAutomatic() throws {}
}
