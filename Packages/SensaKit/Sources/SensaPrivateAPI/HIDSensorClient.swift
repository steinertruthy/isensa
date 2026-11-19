import Foundation
import IOKit

/// One sensor service exposed by the HID event system.
public struct HIDSensorValue: Sendable, Equatable {
    /// `Product` property of the service, e.g. `PMU tdie1`. Never rewritten.
    public let name: String
    public let value: Double
}

/// ⚠️ PRIVATE INTERFACE — temperature sensors published by the HID event system
/// (Apple Silicon PMU, NAND, gas gauge…). Uses undocumented `IOHIDEventSystemClient`
/// functions resolved at runtime. Not thread-safe; own it from a single actor.
public final class HIDSensorClient {
    private typealias CreateClient = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
    private typealias SetMatching = @convention(c) (AnyObject, CFDictionary) -> Int32
    private typealias CopyServices = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
    private typealias CopyProperty = @convention(c) (AnyObject, CFString) -> Unmanaged<AnyObject>?
    private typealias CopyEvent = @convention(c) (AnyObject, Int64, Int32, Int64) -> Unmanaged<AnyObject>?
    private typealias GetFloatValue = @convention(c) (AnyObject, Int32) -> Double

    private static let temperatureEventType: Int64 = 15
    private static var temperatureField: Int32 { Int32(temperatureEventType << 16) }

    private let client: AnyObject
    private let copyServices: CopyServices
    private let copyProperty: CopyProperty
    private let copyEvent: CopyEvent
    private let getFloatValue: GetFloatValue
    private var services: [(name: String, service: AnyObject)] = []

    /// Returns `nil` when any required symbol is missing on this macOS version.
    public init?() {
        let library = PrivateSymbol.iokit
        guard let create = PrivateSymbol.load("IOHIDEventSystemClientCreate", from: library, as: CreateClient.self),
              let setMatching = PrivateSymbol.load("IOHIDEventSystemClientSetMatching", from: library, as: SetMatching.self),
              let copyServices = PrivateSymbol.load("IOHIDEventSystemClientCopyServices", from: library, as: CopyServices.self),
              let copyProperty = PrivateSymbol.load("IOHIDServiceClientCopyProperty", from: library, as: CopyProperty.self),
              let copyEvent = PrivateSymbol.load("IOHIDServiceClientCopyEvent", from: library, as: CopyEvent.self),
              let getFloatValue = PrivateSymbol.load("IOHIDEventGetFloatValue", from: library, as: GetFloatValue.self),
              let client = create(kCFAllocatorDefault)?.takeRetainedValue() else { return nil }
        // Apple vendor page 0xFF00, usage 5 = temperature sensors.
        let matching = ["PrimaryUsagePage": 0xFF00, "PrimaryUsage": 5] as CFDictionary
        _ = setMatching(client, matching)
        self.client = client
        self.copyServices = copyServices
        self.copyProperty = copyProperty
        self.copyEvent = copyEvent
        self.getFloatValue = getFloatValue
        refreshServices()
    }

    /// Re-enumerates services (call after wake; services can come and go).
    public func refreshServices() {
        guard let array = copyServices(client)?.takeRetainedValue() as? [AnyObject] else {
            services = []
            return
        }
        services = array.compactMap { service in
            guard let name = copyProperty(service, "Product" as CFString)?.takeRetainedValue() as? String else { return nil }
            return (name, service)
        }
    }

    public var serviceCount: Int { services.count }

    public func temperatures() -> [HIDSensorValue] {
        services.compactMap { entry in
            guard let event = copyEvent(entry.service, Self.temperatureEventType, 0, 0)?.takeRetainedValue() else { return nil }
            let value = getFloatValue(event, Self.temperatureField)
            // Sensors that are powered down report 0 or nonsense; keep plausible values only.
            guard value.isFinite, value > -40, value < 150 else { return nil }
            return HIDSensorValue(name: entry.name, value: value)
        }
    }
}
