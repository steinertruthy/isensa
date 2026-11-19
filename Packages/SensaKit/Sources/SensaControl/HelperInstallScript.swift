import Foundation

/// Builds the shell scripts that install and remove the privileged helper while Sensa has no
/// Developer ID (which would allow `SMAppService`). They run once, as root, after the user enters an
/// administrator password in the standard macOS prompt.
///
/// Safety of the installation itself:
/// - the helper is copied into a root-owned folder *first* and its code-directory hash verified
///   there, so a file swapped in the user-writable app bundle is rejected;
/// - the launchd job is written by the script itself (no user-writable temporary files);
/// - the helper only accepts connections from the Sensa build whose hash is pinned in the job.
public enum HelperInstallScript {
    public static func install(bundledHelper: String, helperCDHash: String, clientCDHash: String) throws -> String {
        guard isHex(helperCDHash), isHex(clientCDHash) else { throw FanControlFailure("Invalid code signature hash") }
        let label = FanHelper.label
        let binary = FanHelper.installedBinaryPath
        let plist = FanHelper.launchDaemonPath
        return """
        set -e
        /bin/launchctl bootout system/\(label) 2>/dev/null || true
        /bin/mkdir -p /Library/PrivilegedHelperTools
        /bin/rm -f \(binary)
        /bin/cp \(shellQuoted(bundledHelper)) \(binary)
        /usr/sbin/chown root:wheel \(binary)
        /bin/chmod 755 \(binary)
        if ! /usr/bin/codesign --verify -R '=cdhash H"\(helperCDHash)"' \(binary) 2>/dev/null; then
          /bin/rm -f \(binary)
          echo 'The helper does not match this copy of Sensa.' >&2
          exit 1
        fi
        /bin/cat > \(plist) <<'SENSA_PLIST'
        \(launchDaemon(clientCDHash: clientCDHash))
        SENSA_PLIST
        /usr/sbin/chown root:wheel \(plist)
        /bin/chmod 644 \(plist)
        /bin/launchctl bootstrap system \(plist)
        """
    }

    /// Stopping the job sends the helper SIGTERM, which returns the fans to automatic first.
    public static func uninstall() -> String {
        """
        /bin/launchctl bootout system/\(FanHelper.label) 2>/dev/null || true
        /bin/rm -f \(FanHelper.launchDaemonPath) \(FanHelper.installedBinaryPath)
        """
    }

    /// The launchd job: started at boot (so a fan left in manual mode after a crash or power loss is
    /// returned to automatic), relaunched if it crashes, and reachable through its Mach service.
    static func launchDaemon(clientCDHash: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key><string>\(FanHelper.label)</string>
          <key>ProgramArguments</key>
          <array>
            <string>\(FanHelper.installedBinaryPath)</string>
            <string>--client-cdhash</string>
            <string>\(clientCDHash)</string>
          </array>
          <key>MachServices</key><dict><key>\(FanHelper.machServiceName)</key><true/></dict>
          <key>RunAtLoad</key><true/>
          <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
        </dict>
        </plist>
        """
    }

    /// Wraps a shell script for `NSAppleScript`'s `do shell script … with administrator privileges`.
    public static func appleScript(running script: String, prompt: String) -> String {
        "do shell script \"\(appleScriptEscaped(script))\" with prompt \"\(appleScriptEscaped(prompt))\" with administrator privileges"
    }

    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func appleScriptEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }

    static func isHex(_ value: String) -> Bool {
        value.count >= 40 && value.count <= 64 && value.allSatisfy(\.isHexDigit)
    }
}
