import AppKit
import Foundation
import iSensaControl

/// Fan control through the privileged helper, over XPC. Both ends verify each other's code signature:
/// the helper accepts only the iSensa build that installed it, and iSensa talks only to the helper
/// bundled with it.
final class XPCFanControlService: FanControlService, @unchecked Sendable {
    let isDemo = false
    private let lock = NSLock()
    private var connection: NSXPCConnection?
    private let bundledHelperPath = Bundle.main.bundleURL.appendingPathComponent(FanHelper.bundledRelativePath).path
    private lazy var bundledHelperHash = CodeSignature.cdHash(atPath: bundledHelperPath)
    private lazy var ownHash = CodeSignature.ownCDHash()

    func state() async -> FanHelperState {
        guard FileManager.default.fileExists(atPath: FanHelper.installedBinaryPath) else { return .notInstalled }
        guard let bundled = bundledHelperHash, CodeSignature.cdHash(atPath: FanHelper.installedBinaryPath) == bundled,
              let own = ownHash, pinnedClientHash() == own else { return .needsUpdate }
        do {
            let version = try await call { proxy, done in proxy.handshake { done(.success($0)) } }
            guard version == FanHelper.protocolVersion else { return .needsUpdate }
            let data = try await call { proxy, done in proxy.status { done(.success($0)) } }
            let status = data.flatMap { try? JSONDecoder().decode(HelperStatus.self, from: $0) } ?? HelperStatus()
            return .ready(status)
        } catch {
            return .unreachable("\(error)")
        }
    }

    func apply(_ targets: [FanTarget]) async throws {
        let payload = try JSONEncoder().encode(targets)
        // The first switch to manual can take several seconds on M3 and later (thermal manager handover).
        let message = try await call(timeout: 20) { proxy, done in proxy.apply(payload) { done(.success($0)) } }
        if let message { throw FanControlFailure(message) }
    }

    func heartbeat() async -> Bool {
        (try? await call { proxy, done in proxy.heartbeat { done(.success($0)) } }) ?? false
    }

    func restoreAutomatic() async throws {
        // The firmware can take several seconds to reclaim the fans on M3 and later.
        let message = try await call(timeout: 20) { proxy, done in proxy.restoreAutomatic { done(.success($0)) } }
        if let message { throw FanControlFailure(message) }
    }

    func install() async throws {
        guard let helperHash = bundledHelperHash, let clientHash = ownHash else {
            throw FanControlFailure(String(localized: "This copy of iSensa is missing its fan helper or code signature."))
        }
        let script = try HelperInstallScript.install(bundledHelper: bundledHelperPath, helperCDHash: helperHash, clientCDHash: clientHash)
        try await runAsAdministrator(script, prompt: String(localized: "iSensa wants to install its fan helper."))
        resetConnection()
    }

    func uninstall() async throws {
        try await runAsAdministrator(HelperInstallScript.uninstall(), prompt: String(localized: "iSensa wants to remove its fan helper."))
        resetConnection()
    }

    // MARK: - Helpers

    /// The client hash pinned in the installed launchd job.
    private func pinnedClientHash() -> String? {
        guard let plist = NSDictionary(contentsOfFile: FanHelper.launchDaemonPath),
              let arguments = plist["ProgramArguments"] as? [String],
              let flag = arguments.firstIndex(of: "--client-cdhash"), flag + 1 < arguments.count else { return nil }
        return arguments[flag + 1]
    }

    private func proxyConnection() -> NSXPCConnection {
        lock.lock()
        defer { lock.unlock() }
        if let connection { return connection }
        let connection = NSXPCConnection(machServiceName: FanHelper.machServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: FanHelperXPC.self)
        if let hash = bundledHelperHash {
            connection.setCodeSigningRequirement("identifier \"\(FanHelper.label)\" and cdhash H\"\(hash)\"")
        }
        connection.invalidationHandler = { [weak self] in self?.resetConnection() }
        connection.interruptionHandler = { [weak self] in self?.resetConnection() }
        connection.resume()
        self.connection = connection
        return connection
    }

    private func resetConnection() {
        lock.lock()
        let old = connection
        connection = nil
        lock.unlock()
        old?.invalidate()
    }

    /// Calls the helper with a timeout; connection errors surface as thrown errors.
    private func call<T: Sendable>(
        timeout: TimeInterval = 5,
        _ body: @escaping @Sendable (FanHelperXPC, @escaping @Sendable (Result<T, Error>) -> Void) -> Void
    ) async throws -> T {
        let connection = proxyConnection()
        return try await withCheckedThrowingContinuation { continuation in
            let once = Once(continuation)
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in once.resume(.failure(error)) }
            guard let helper = proxy as? FanHelperXPC else {
                once.resume(.failure(FanControlFailure("Unexpected helper interface")))
                return
            }
            body(helper) { once.resume($0) }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                once.resume(.failure(FanControlFailure(String(localized: "The fan helper did not answer in time."))))
            }
        }
    }

    private func runAsAdministrator(_ script: String, prompt: String) async throws {
        let source = HelperInstallScript.appleScript(running: script, prompt: prompt)
        try await Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            guard let error else { return }
            // -128: the user cancelled the password prompt.
            if (error[NSAppleScript.errorNumber] as? Int) == -128 { throw CancellationError() }
            throw FanControlFailure(error[NSAppleScript.errorMessage] as? String ?? "\(error)")
        }.value
    }
}

/// Resumes a continuation exactly once (reply, error handler or timeout — whichever comes first).
private final class Once<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?

    init(_ continuation: CheckedContinuation<T, Error>) { self.continuation = continuation }

    func resume(_ result: Result<T, Error>) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(with: result)
    }
}
