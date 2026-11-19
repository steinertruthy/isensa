import AppKit
import SensaControl
import SensaCore
import SensaProviders

/// Moves items to the Trash like Finder: without a password when macOS allows it, and with the
/// administrator password — asked by macOS, typed by the person — for items another user owns
/// (apps installed by the App Store or by an installer package belong to the system).
struct AdministratorTrash: FileTrashing {
    let base = TrashRemover()

    func moveToTrash(_ url: URL) async throws -> URL {
        do {
            return try await base.moveToTrash(url)
        } catch where Self.isPermissionError(error) {
            let destination = Self.trashDestination(for: url)
            let prompt = String(format: String(localized: "Sensa wants to move “%@” to the Trash."), url.lastPathComponent)
            try await Self.move(url, to: destination, prompt: prompt)
            return destination
        }
    }

    func putBack(_ trashed: URL, to original: URL) async throws {
        do {
            try await base.putBack(trashed, to: original)
        } catch where Self.isPermissionError(error) {
            let prompt = String(format: String(localized: "Sensa wants to put “%@” back."), original.lastPathComponent)
            try await Self.move(trashed, to: original, prompt: prompt)
        }
    }

    static func isPermissionError(_ error: Error) -> Bool {
        let error = error as NSError
        if error.domain == NSCocoaErrorDomain, error.code == NSFileWriteNoPermissionError { return true }
        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError, underlying.domain == NSPOSIXErrorDomain {
            return underlying.code == Int(EACCES) || underlying.code == Int(EPERM)
        }
        return error.domain == NSPOSIXErrorDomain && (error.code == Int(EACCES) || error.code == Int(EPERM))
    }

    /// `~/.Trash/Name.app`, or `Name 14.03.27.app` when the Trash already holds one, as Finder names them.
    static func trashDestination(for url: URL) -> URL {
        let trash = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        let plain = trash.appendingPathComponent(url.lastPathComponent)
        guard FileManager.default.fileExists(atPath: plain.path) else { return plain }
        let time = Date().formatted(.verbatim("\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)).\(minute: .twoDigits).\(second: .twoDigits)",
                                               timeZone: .current, calendar: .current))
        let name = url.deletingPathExtension().lastPathComponent + " " + time
        return trash.appendingPathComponent(url.pathExtension.isEmpty ? name : name + "." + url.pathExtension)
    }

    /// `mv -n` (never overwrites) with both paths quoted for the shell and escaped for AppleScript.
    private static func move(_ source: URL, to destination: URL, prompt: String) async throws {
        let command = "/bin/mv -n -- \(HelperInstallScript.shellQuoted(source.path)) \(HelperInstallScript.shellQuoted(destination.path))"
        let script = HelperInstallScript.appleScript(running: command, prompt: prompt)
        try await Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            guard let error else { return }
            // -128: the person cancelled the password prompt.
            if (error[NSAppleScript.errorNumber] as? Int) == -128 { throw CancellationError() }
            throw FanControlFailure(error[NSAppleScript.errorMessage] as? String ?? "\(error)")
        }.value
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSFilePathErrorKey: source.path])
        }
    }
}
