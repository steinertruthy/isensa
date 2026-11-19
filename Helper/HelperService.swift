import Foundation
import iSensaControl

/// XPC endpoint. Every call hops onto the helper's serial queue, where the safety controller lives.
final class HelperService: NSObject, FanHelperXPC, @unchecked Sendable {
    private let controller: FanSafetyController
    private let queue: DispatchQueue

    init(controller: FanSafetyController, queue: DispatchQueue) {
        self.controller = controller
        self.queue = queue
    }

    func handshake(reply: @escaping @Sendable (Int) -> Void) {
        reply(FanHelper.protocolVersion)
    }

    func status(reply: @escaping @Sendable (Data?) -> Void) {
        queue.async { reply(try? JSONEncoder().encode(self.controller.status)) }
    }

    func apply(_ targets: Data, reply: @escaping @Sendable (String?) -> Void) {
        queue.async {
            do {
                let decoded = try JSONDecoder().decode([FanTarget].self, from: targets)
                try self.controller.apply(decoded, now: Date())
                reply(nil)
            } catch {
                reply("\(error)")
            }
        }
    }

    func heartbeat(reply: @escaping @Sendable (Bool) -> Void) {
        queue.async { reply(self.controller.heartbeat(now: Date())) }
    }

    func restoreAutomatic(reply: @escaping @Sendable (String?) -> Void) {
        queue.async {
            self.controller.requestAutomatic()
            reply(self.controller.status.lastError)
        }
    }
}
