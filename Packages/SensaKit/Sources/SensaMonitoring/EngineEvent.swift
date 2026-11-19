import Foundation
import SensaCore

/// Everything the engine publishes to its consumers.
public enum EngineEvent: Sendable {
    case fragment(any SnapshotFragment)
    case capability(Feature, CapabilityState)
}
