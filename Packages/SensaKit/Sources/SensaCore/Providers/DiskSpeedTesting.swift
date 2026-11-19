import Foundation

/// A sequential read and write test of one volume. It writes a temporary file, so it only ever
/// runs when the person starts it, and the file is always deleted afterwards.
public protocol DiskSpeedTesting: Sendable {
    func run(in directory: URL, bytes: Int, progress: @escaping @Sendable (DiskSpeedProgress) -> Void) async throws -> DiskSpeedResult
}

public struct DiskSpeedProgress: Sendable, Equatable {
    public enum Phase: Sendable, Equatable { case writing, reading }
    public let phase: Phase
    /// Progress through the current phase, `0...1`.
    public let fraction: Double

    public init(phase: Phase, fraction: Double) {
        self.phase = phase
        self.fraction = fraction
    }
}

public struct DiskSpeedResult: Sendable, Equatable {
    /// Bytes per second, including the time to flush the data to the disk.
    public let writeSpeed: Double
    public let readSpeed: Double
    public let bytes: Int
    public let isDemo: Bool

    public init(writeSpeed: Double, readSpeed: Double, bytes: Int, isDemo: Bool = false) {
        self.writeSpeed = writeSpeed
        self.readSpeed = readSpeed
        self.bytes = bytes
        self.isDemo = isDemo
    }
}

public enum DiskSpeedTestError: Error, Equatable, Sendable {
    case notEnoughSpace
    case failed(String)
}
