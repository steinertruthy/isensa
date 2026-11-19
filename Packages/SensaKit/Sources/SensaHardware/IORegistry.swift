import Foundation
import IOKit

/// Read-only helpers over the I/O Registry (public IOKit API).
public enum IORegistry {
    /// Properties of every service matching an IOKit class name.
    public static func properties(ofClass className: String) -> [[String: Any]] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(className), &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }
        var result: [[String: Any]] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            if let properties = properties(of: service) { result.append(properties) }
        }
        return result
    }

    /// Properties of the first service with the given name (e.g. `AppleSmartBattery`).
    public static func properties(ofServiceNamed name: String) -> [String: Any]? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching(name))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return properties(of: service)
    }

    public static func serviceExists(named name: String) -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching(name))
        guard service != 0 else { return false }
        IOObjectRelease(service)
        return true
    }

    /// A property from the device tree plane, e.g. `IODeviceTree:/product` → `product-name`.
    public static func deviceTreeProperty(path: String, key: String) -> Any? {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:\(path)")
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        return IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    /// Decodes device-tree data properties that hold NUL-terminated strings.
    public static func string(fromDeviceTreeValue value: Any?) -> String? {
        if let string = value as? String { return string }
        guard let data = value as? Data else { return nil }
        let string = CString.decode(bytes: data)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return string?.isEmpty == false ? string : nil
    }

    private static func properties(of service: io_registry_entry_t) -> [String: Any]? {
        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dictionary = unmanaged?.takeRetainedValue() as? [String: Any] else { return nil }
        return dictionary
    }
}
