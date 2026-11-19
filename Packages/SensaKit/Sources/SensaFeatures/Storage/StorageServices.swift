import Foundation
import SensaCore

/// Actions the Storage screen can take. Both only run when the person asks for them.
public struct StorageServices: Sendable {
    public var speedTester: (any DiskSpeedTesting)?
    /// Unmounts and ejects the volume at a mount point.
    public var eject: (@Sendable (URL) async throws -> Void)?
    /// Space analysis and removal to the Trash; one per session.
    public var spaceAnalysis: SpaceAnalysis?

    public init(
        speedTester: (any DiskSpeedTesting)? = nil, eject: (@Sendable (URL) async throws -> Void)? = nil, spaceAnalysis: SpaceAnalysis? = nil
    ) {
        self.speedTester = speedTester
        self.eject = eject
        self.spaceAnalysis = spaceAnalysis
    }
}
