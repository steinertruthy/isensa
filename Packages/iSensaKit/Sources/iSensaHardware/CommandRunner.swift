import Foundation

/// Runs a system command-line tool and returns its standard output. Only absolute paths of tools
/// shipped with macOS are used, never a shell, and output is parsed as data, not executed.
public enum CommandRunner {
    public static func run(_ executable: String, _ arguments: [String], timeout: TimeInterval = 5) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        do { try process.run() } catch { return nil }
        // Read concurrently so a large output cannot fill the pipe and block the tool.
        let reader = OutputReader(output.fileHandleForReading)
        if finished.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            return nil
        }
        let data = reader.wait()
        return process.terminationStatus == 0 ? data : nil
    }
}

private final class OutputReader: @unchecked Sendable {
    private var data = Data()
    private let done = DispatchSemaphore(value: 0)

    init(_ handle: FileHandle) {
        DispatchQueue.global(qos: .utility).async {
            self.data = handle.readDataToEndOfFile()
            self.done.signal()
        }
    }

    func wait() -> Data {
        done.wait()
        return data
    }
}
