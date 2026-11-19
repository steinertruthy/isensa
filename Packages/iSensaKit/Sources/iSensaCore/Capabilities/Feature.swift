import Foundation

/// A user-visible capability whose availability depends on the specific Mac.
public enum Feature: String, Sendable, Codable, CaseIterable, Hashable {
    case cpuUsage
    case cpuFrequency
    case gpuUsage
    case memory
    case battery
    case powerAdapter
    case thermalState
    case temperatureSensors
    case fans
    case fanControl
    case powerConsumption
    case storage
    case network
    case wifiDetails
    case processes
}
