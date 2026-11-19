import Foundation
import iSensaCore

/// Demo mode: pretends to test for a moment and returns labelled demo figures. Never touches a disk.
public struct DemoDiskSpeedTester: DiskSpeedTesting {
    public init() {}

    public func run(in directory: URL, bytes: Int, progress: @escaping @Sendable (DiskSpeedProgress) -> Void) async throws -> DiskSpeedResult {
        for phase in [DiskSpeedProgress.Phase.writing, .reading] {
            for step in 1...5 {
                try await Task.sleep(for: .milliseconds(80))
                progress(DiskSpeedProgress(phase: phase, fraction: Double(step) / 5))
            }
        }
        return DiskSpeedResult(writeSpeed: 3_100_000_000, readSpeed: 4_200_000_000, bytes: bytes, isDemo: true)
    }

    /// Demo "eject": succeeds without touching anything.
    public static let eject: @Sendable (URL) async throws -> Void = { _ in
        try await Task.sleep(for: .milliseconds(200))
    }
}
