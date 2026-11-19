import Darwin
import Foundation
import iSensaCore

/// Sequential write then read of one temporary file with the file cache bypassed (`F_NOCACHE`),
/// so the read comes from the disk and not from memory. The write is timed up to a full flush
/// (`F_FULLFSYNC`). The file is deleted whatever happens.
public struct DiskSpeedTester: DiskSpeedTesting {
    static let chunkSize = 8 << 20
    /// Space that must stay free besides the test file.
    static let headroom: UInt64 = 2 << 30

    public init() {}

    public func run(in directory: URL, bytes: Int, progress: @escaping @Sendable (DiskSpeedProgress) -> Void) async throws -> DiskSpeedResult {
        let free = (try? directory.resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity).map { UInt64(max($0, 0)) }
        guard let free, free >= UInt64(bytes) + Self.headroom else { throw DiskSpeedTestError.notEnoughSpace }
        let file = directory.appendingPathComponent(".isensa-speed-test-\(UUID().uuidString)")
        let cancellation = Cancellation()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                Thread.detachNewThread {
                    continuation.resume(with: Result { try Self.measure(file: file, bytes: bytes, cancellation: cancellation, progress: progress) })
                }
            }
        } onCancel: {
            cancellation.cancel()
        }
    }

    private static func measure(
        file: URL, bytes: Int, cancellation: Cancellation, progress: @Sendable (DiskSpeedProgress) -> Void
    ) throws -> DiskSpeedResult {
        let descriptor = open(file.path, O_CREAT | O_EXCL | O_RDWR, 0o600)
        guard descriptor >= 0 else { throw DiskSpeedTestError.failed(String(cString: strerror(errno))) }
        defer {
            close(descriptor)
            unlink(file.path)
        }
        _ = fcntl(descriptor, F_NOCACHE, 1)
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: chunkSize, alignment: 16_384)
        defer { buffer.deallocate() }
        arc4random_buf(buffer, chunkSize) // Incompressible data.
        let chunks = max(bytes / chunkSize, 1)

        let writeStart = DispatchTime.now()
        for index in 0..<chunks {
            if cancellation.isCancelled { throw CancellationError() }
            guard pwrite(descriptor, buffer, chunkSize, off_t(index * chunkSize)) == chunkSize else {
                throw DiskSpeedTestError.failed(String(cString: strerror(errno)))
            }
            progress(DiskSpeedProgress(phase: .writing, fraction: Double(index + 1) / Double(chunks)))
        }
        _ = fcntl(descriptor, F_FULLFSYNC)
        let writeTime = seconds(since: writeStart)

        let readStart = DispatchTime.now()
        for index in 0..<chunks {
            if cancellation.isCancelled { throw CancellationError() }
            guard pread(descriptor, buffer, chunkSize, off_t(index * chunkSize)) == chunkSize else {
                throw DiskSpeedTestError.failed(String(cString: strerror(errno)))
            }
            progress(DiskSpeedProgress(phase: .reading, fraction: Double(index + 1) / Double(chunks)))
        }
        let readTime = seconds(since: readStart)
        let total = Double(chunks * chunkSize)
        return DiskSpeedResult(writeSpeed: total / writeTime, readSpeed: total / readTime, bytes: chunks * chunkSize)
    }

    private static func seconds(since start: DispatchTime) -> Double {
        max(Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1e9, 1e-6)
    }
}

private final class Cancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool { lock.withLock { cancelled } }
    func cancel() { lock.withLock { cancelled = true } }
}
