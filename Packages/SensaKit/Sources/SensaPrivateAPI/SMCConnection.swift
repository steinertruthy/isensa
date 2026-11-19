import CSensaPrivate
import Foundation
import IOKit

public enum SMCError: Error, Sendable, Equatable {
    case serviceNotFound
    case openFailed(kern_return_t)
    case callFailed(kern_return_t)
    case keyNotFound(String)
    case firmwareError(UInt8)
}

/// ⚠️ PRIVATE INTERFACE — read-only connection to the System Management Controller.
///
/// Uses the undocumented `AppleSMC` user client. Reading requires no privileges.
/// This type deliberately exposes **no write operation**: writes live only in the
/// privileged helper, behind a whitelist. Not thread-safe; own it from a single actor.
public final class SMCConnection {
    private var connection: io_connect_t = 0
    private var keyInfoCache: [SMCKey: SensaSMCKeyInfo] = [:]

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
        var input = SensaSMCKeyData()
        input.data8 = UInt8(kSensaSMCGetKeyFromIndex)
        input.data32 = UInt32(index)
        let output = try call(input)
        return SMCKey(code: output.key)
    }

    public func read(_ key: SMCKey) throws -> SMCValue {
        let info = try keyInfo(key)
        var input = SensaSMCKeyData()
        input.key = key.code
        input.keyInfo.dataSize = info.dataSize
        input.data8 = UInt8(kSensaSMCReadKey)
        let output = try call(input)
        let size = min(Int(info.dataSize), 32)
        let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(size)) }
        return SMCValue(key: key, dataType: SMCKey.fourCharacterString(info.dataType), bytes: bytes)
    }

    /// Reads a numeric key, returning `nil` if it does not exist or cannot be decoded.
    public func number(_ key: SMCKey) -> Double? {
        (try? read(key))?.doubleValue
    }

    public func dataType(of key: SMCKey) throws -> String {
        SMCKey.fourCharacterString(try keyInfo(key).dataType)
    }

    private func keyInfo(_ key: SMCKey) throws -> SensaSMCKeyInfo {
        if let cached = keyInfoCache[key] { return cached }
        var input = SensaSMCKeyData()
        input.key = key.code
        input.data8 = UInt8(kSensaSMCGetKeyInfo)
        let output = try call(input)
        guard output.keyInfo.dataSize > 0 else { throw SMCError.keyNotFound(key.description) }
        keyInfoCache[key] = output.keyInfo
        return output.keyInfo
    }

    private func call(_ input: SensaSMCKeyData) throws -> SensaSMCKeyData {
        var input = input
        var output = SensaSMCKeyData()
        var outputSize = MemoryLayout<SensaSMCKeyData>.stride
        let result = IOConnectCallStructMethod(
            connection, UInt32(kSensaSMCHandleYPCEvent),
            &input, MemoryLayout<SensaSMCKeyData>.stride,
            &output, &outputSize
        )
        guard result == kIOReturnSuccess else { throw SMCError.callFailed(result) }
        // Firmware result 132 (0x84) means "key not found".
        if output.result == 132 { throw SMCError.keyNotFound(SMCKey(code: input.key).description) }
        guard output.result == 0 else { throw SMCError.firmwareError(output.result) }
        return output
    }
}
