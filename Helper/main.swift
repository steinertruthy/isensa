// iSensa's privileged helper: the only process that writes fan settings. Runs as root under launchd.
//
// Safety does not depend on the app: the helper returns fans to automatic when it starts, when the
// app disconnects, when the app stops renewing its lease, under serious thermal pressure, on SIGTERM
// (uninstall, shutdown) and after any failed write.
import Foundation

guard let runtime = HelperRuntime(arguments: CommandLine.arguments) else {
    FileHandle.standardError.write(Data("Usage: io.github.steinertruthy.iSensa.helper --client-cdhash <hex>\n".utf8))
    exit(64)
}
runtime.run()
