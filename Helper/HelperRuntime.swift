import Foundation
import iSensaControl
import iSensaPrivateAPI

/// Owns the helper's state. Everything mutable is touched only on `queue`.
final class HelperRuntime: NSObject, NSXPCListenerDelegate, @unchecked Sendable {
    /// Seconds without clients or overrides before the helper exits (launchd restarts it on demand).
    static let idleExit: TimeInterval = 120

    private let queue = DispatchQueue(label: "io.github.steinertruthy.iSensa.helper")
    private let clientRequirement: String
    private let controller: FanSafetyController
    private var listener: NSXPCListener?
    private var sources: [DispatchSourceProtocol] = []
    private var connections = 0
    private var idleSince = Date()

    init?(arguments: [String]) {
        guard let flag = arguments.firstIndex(of: "--client-cdhash"), flag + 1 < arguments.count else { return nil }
        let hash = arguments[flag + 1]
        guard hash.count >= 40, hash.count <= 64, hash.allSatisfy(\.isHexDigit) else { return nil }
        // Only the iSensa build that installed the helper may connect.
        clientRequirement = "identifier \"io.github.steinertruthy.iSensa\" and cdhash H\"\(hash)\""
        let hardware: FanHardware
        do {
            hardware = SMCFanHardware(writer: try SMCFanWriter())
        } catch {
            hardware = UnavailableFanHardware(reason: "SMC unavailable: \(error)")
        }
        controller = FanSafetyController(hardware: hardware)
    }

    func run() -> Never {
        queue.sync { controller.start() }
        let listener = NSXPCListener(machServiceName: FanHelper.machServiceName)
        listener.delegate = self
        listener.resume()
        self.listener = listener
        installSignalHandlers()
        startSafetyTick()
        dispatchMain()
    }

    // MARK: - Connections

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(clientRequirement)
        connection.exportedInterface = NSXPCInterface(with: FanHelperXPC.self)
        connection.exportedObject = HelperService(controller: controller, queue: queue)
        connection.invalidationHandler = { [weak self] in self?.connectionEnded() }
        queue.sync { connections += 1 }
        connection.resume()
        return true
    }

    private func connectionEnded() {
        queue.async {
            self.connections = max(self.connections - 1, 0)
            guard self.connections == 0 else { return }
            self.controller.clientDisconnected()
            self.idleSince = Date()
        }
    }

    // MARK: - Safety

    /// Stop signals (uninstall, shutdown, `launchctl bootout`): restore automatic, then exit.
    private func installSignalHandlers() {
        for stopSignal in [SIGTERM, SIGINT, SIGHUP] {
            signal(stopSignal, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: stopSignal, queue: queue)
            source.setEventHandler { [controller] in
                controller.stopping()
                exit(0)
            }
            source.resume()
            sources.append(source)
        }
    }

    /// Once a second: lease expiry and macOS thermal pressure. Exits when idle.
    private func startSafetyTick() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1, repeating: 1, leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in self?.tick() }
        timer.resume()
        sources.append(timer)
    }

    private func tick() {
        let pressure = ProcessInfo.processInfo.thermalState
        controller.tick(now: Date(), thermalPressureIsHigh: pressure == .serious || pressure == .critical)
        if !controller.status.isManual, connections == 0, Date().timeIntervalSince(idleSince) > Self.idleExit {
            exit(0)
        }
    }
}
