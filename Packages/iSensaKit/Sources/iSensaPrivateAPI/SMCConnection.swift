import CiSensaPrivate
import Foundation
import IOKit

public enum SMCError: Error, Sendable, Equatable, CustomStringConvertible {
    case serviceNotFound
    case openFailed(kern_return_t)
    case callFailed(kern_return_t)
    case keyNotFound(String)
    case firmwareError(UInt8)
    case sizeMismatch(String)
    case keyNotWritable(String)
    /// The firmware kept refusing manual mode (the macOS thermal manager did not release the fans).
    case manualModeRefused(String)

    /// "Bad command": on M3 and later, the answer to a fan mode write while macOS' thermal manager holds the fans.
    public static let badCommand: UInt8 = 0x82

    public var description: String {
        switch self {
        case .serviceNotFound: "SMC not found"
        case let .openFailed(code): "SMC open failed (\(code))"
        case let .callFailed(code): "SMC call failed (\(code))"
        case let .keyNotFound(key): "SMC key \(key) not found"
        case let .firmwareError(code): "SMC error 0x\(String(code, radix: 16))"
        case let .sizeMismatch(key): "SMC key \(key): size mismatch"
        case let .keyNotWritable(key): "SMC key \(key) is not writable"
        case let .manualModeRefused(key): "SMC refused manual mode on \(key)"
        }
    }
}

/// ⚠️ PRIVATE INTERFACE — read-only connection to the System Management Controller.
///
/// Uses the undocumented `AppleSMC` user client. Reading requires no privileges.
/// This type deliberately exposes **no public write operation**: writes go only through
/// `SMCFanWriter`, which whitelists fan keys and is used only by the privileged helper.
/// Not thread-safe; own it from a single actor.
public final class SMCConnection {
    private var connection: io_connect_t = 0
    private var keyInfoCache: [SMCKey: iSensaSMCKeyInfo] = [:]

    public init() throws {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { throw SMCError.serviceNotFound }
        defer { IOObjectRelease(service) }
        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        guard result == kIOReturnSuccess else { throw SMCError.openFailed(result) }
    }

    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }

    /// Number of keys exposed by the firmware.
    public func keyCount() throws -> Int {
        Int(try read("#KEY").doubleValue ?? 0)
    }

    public func key(at index: Int) throws -> SMCKey {
        var input = iSensaSMCKeyData()
        input.data8 = UInt8(kiSensaSMCGetKeyFromIndex)
        input.data32 = UInt32(index)
        let output = try call(input)
        return SMCKey(code: output.key)
    }

    public func read(_ key: SMCKey) throws -> SMCValue {
        let info = try keyInfo(key)
        var input = iSensaSMCKeyData()
        input.key = key.code
        input.keyInfo.dataSize = info.dataSize
        input.data8 = UInt8(kiSensaSMCReadKey)
        let output = try call(input)
        let size = min(Int(info.dataSize), 32)
        let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(size)) }
        return SMCValue(key: key, dataType: SMCKey.fourCharacterString(info.dataType), bytes: bytes)
    }

    /// Reads a numeric key, returning `nil` if it does not exist or cannot be decoded.
    public func number(_ key: SMCKey) -> Double? {
        (try? read(key))?.doubleValue
    }

    /// Writes raw bytes. Internal on purpose — see `SMCFanWriter`. Requires root.
    func write(_ key: SMCKey, bytes: [UInt8]) throws {
        let info = try keyInfo(key)
        guard bytes.count == Int(info.dataSize), bytes.count <= 32 else { throw SMCError.sizeMismatch(key.description) }
        var input = iSensaSMCKeyData()
        input.key = key.code
        input.keyInfo.dataSize = info.dataSize
        input.data8 = UInt8(kiSensaSMCWriteKey)
        withUnsafeMutableBytes(of: &input.bytes) { buffer in
            for (offset, byte) in bytes.enumerated() { buffer[offset] = byte }
        }
        _ = try call(input)
    }

    public func dataType(of key: SMCKey) throws -> String {
        SMCKey.fourCharacterString(try keyInfo(key).dataType)
    }

    private func keyInfo(_ key: SMCKey) throws -> iSensaSMCKeyInfo {
        if let cached = keyInfoCache[key] { return cached }
        var input = iSensaSMCKeyData()
        input.key = key.code
        input.data8 = UInt8(kiSensaSMCGetKeyInfo)
        let output = try call(input)
        guard output.keyInfo.dataSize > 0 else { throw SMCError.keyNotFound(key.description) }
        keyInfoCache[key] = output.keyInfo
        return output.keyInfo
    }

    private func call(_ input: iSensaSMCKeyData) throws -> iSensaSMCKeyData {
        var input = input
        var output = iSensaSMCKeyData()
        var outputSize = MemoryLayout<iSensaSMCKeyData>.stride
        let result = IOConnectCallStructMethod(
            connection, UInt32(kiSensaSMCHandleYPCEvent),
            &input, MemoryLayout<iSensaSMCKeyData>.stride,
            &output, &outputSize
        )
        guard result == kIOReturnSuccess else { throw SMCError.callFailed(result) }
        // Firmware result 132 (0x84) means "key not found".
        if output.result == 132 { throw SMCError.keyNotFound(SMCKey(code: input.key).description) }
        guard output.result == 0 else { throw SMCError.firmwareError(output.result) }
        return output
    }
}
