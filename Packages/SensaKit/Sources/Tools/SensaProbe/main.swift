// sensa-probe — development tool that dumps every sensor Sensa can see on this Mac.
// Used to validate the sensor catalog (idle vs. load) before marking mappings as verified.
//
// Usage: sensa-probe [smc|hid|ioreport|dvfs|smart|all|space] [prefixes or folders...]
//   sensa-probe smc T F P     → SMC keys starting with T, F or P with their decoded values
import Foundation
import SensaHardware
import SensaPrivateAPI
import SensaCore
import SensaProviders

let arguments = CommandLine.arguments.dropFirst()
let mode = arguments.first ?? "all"
let prefixes = Array(arguments.dropFirst())

func line(_ text: String) { FileHandle.standardOutput.write(Data((text + "\n").utf8)) }

line("# model \(Sysctl.string("hw.model") ?? "?") · \(Sysctl.string("machdep.cpu.brand_string") ?? "?")")

if mode == "space" {
    // sensa-probe space <folder>… → sizes as the Free Up Space analysis measures them (read-only).
    let roots = prefixes.map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
    let semaphore = DispatchSemaphore(value: 0)
    // Detached: top-level code runs on the main actor, which `semaphore.wait()` blocks.
    Task.detached {
        let started = Date()
        do {
            let report = try await DiskUsageScanner().scan(roots: roots) { _ in }
            line("space\tscanned \(report.itemCount) files in \(String(format: "%.1f", Date().timeIntervalSince(started))) s")
            for root in report.roots {
                line("space\t\(root.size / 1_000)\tKB\t\(root.url.path)")
                root.children.prefix(8).forEach { line("space\t  \($0.size / 1_000)\tKB\t\($0.name)") }
            }
            report.largestFiles.prefix(5).forEach { line("largest\t\($0.size / 1_000_000) MB\t\($0.url.path)") }
            report.unreadable.prefix(10).forEach { line("unreadable\t\($0.path)") }
        } catch {
            line("space\tfailed: \(error)")
        }
        semaphore.signal()
    }
    semaphore.wait()
    exit(0)
}

if mode == "smc" || mode == "all" {
    do {
        let smc = try SMCConnection()
        let count = try smc.keyCount()
        line("# SMC keys: \(count)")
        for index in 0..<count {
            guard let key = try? smc.key(at: index) else { continue }
            let name = key.description
            if !prefixes.isEmpty, !prefixes.contains(where: { name.hasPrefix($0) }) { continue }
            guard let value = try? smc.read(key) else { continue }
            let decoded = value.doubleValue.map { String(format: "%.3f", $0) } ?? "–"
            let hex = value.bytes.map { String(format: "%02x", $0) }.joined()
            line("smc\t\(name)\t\(value.dataType)\t\(decoded)\t\(hex)")
        }
    } catch {
        line("# SMC unavailable: \(error)")
    }
}

if mode == "hid" || mode == "all" {
    if let hid = HIDSensorClient() {
        line("# HID temperature services: \(hid.serviceCount)")
        for sensor in hid.temperatures().sorted(by: { $0.name < $1.name }) {
            line("hid\t\(sensor.name)\t\(String(format: "%.2f", sensor.value))")
        }
    } else {
        line("# HID sensor client unavailable")
    }
}

if mode == "ioreport" {
    let groups: [(group: String, subgroup: String?)] = [
        ("Energy Model", nil), ("CPU Stats", "CPU Core Performance States"), ("GPU Stats", "GPU Performance States")
    ]
    if let sampler = IOReportSampler(groups: groups) {
        _ = sampler.sample()
        Thread.sleep(forTimeInterval: 1)
        if let result = sampler.sample() {
            line("# IOReport channels: \(result.channels.count) over \(String(format: "%.3f", result.interval)) s")
            for channel in result.channels {
                let value: String = switch channel.value {
                case let .simple(number): "\(number) \(channel.unit ?? "")"
                case let .states(states): states.filter { $0.residency > 0 }.map { "\($0.name)=\($0.residency)" }.joined(separator: " ")
                case .unsupported: "unsupported"
                }
                line("ioreport\t\(channel.group)\t\(channel.subgroup)\t\(channel.name)\t\(value)")
            }
        }
    } else {
        line("# IOReport unavailable")
    }
}

if mode == "dvfs" {
    for key in ["voltage-states1-sram", "voltage-states5-sram", "voltage-states9", "voltage-states9-sram"] {
        guard let data = IORegistry.deviceTreeProperty(path: "/arm-io/pmgr", key: key) as? Data else {
            line("dvfs\t\(key)\tmissing")
            continue
        }
        let words = stride(from: 0, to: data.count - 3, by: 4).map { offset in
            data[data.startIndex + offset..<data.startIndex + offset + 4].enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * UInt32($1.offset)) }
        }
        let pairs = stride(from: 0, to: words.count - 1, by: 2).map { "\(words[$0])/\(words[$0 + 1])" }
        line("dvfs\t\(key)\t\(pairs.joined(separator: " "))")
    }
}

if mode == "smart" {
    if let log = NVMeHealthReader.read() {
        line("smart\t\(log)")
    } else {
        line("# NVMe SMART unavailable")
    }
}

if mode == "live" {
    // Samples the Stage 3 providers twice, two seconds apart, and prints what the app would show.
    let semaphore = DispatchSemaphore(value: 0)
    Task.detached {
        let providers: [any MetricProvider] = [
            PerformanceProvider(), EnergyProvider(), ProcessProvider(limit: 5), WiFiProvider(), StorageProvider(), NetworkProvider()
        ]
        for provider in providers {
            line("probe\t\(provider.id)\t\(await provider.probe())")
            _ = try? await provider.sample()
        }
        try? await Task.sleep(for: .seconds(2))
        for provider in providers {
            guard let fragment = try? await provider.sample() else {
                line("live\t\(provider.id)\tfailed")
                continue
            }
            describe(fragment).forEach(line)
        }
        semaphore.signal()
    }
    semaphore.wait()
}

func describe(_ fragment: any SnapshotFragment) -> [String] {
    func number(_ value: Double?, _ format: String = "%.0f") -> String { value.map { String(format: format, $0) } ?? "–" }
    switch fragment {
    case let performance as PerformanceSnapshot:
        return performance.clusters.map { cluster in
            let frequency = "\(number(cluster.averageFrequency)) MHz of \(number(cluster.maximumFrequency))"
            return "live\tfrequency\t\(cluster.kind)\t\(frequency)\tactive \(number(cluster.activeResidency * 100))%"
        }
    case let power as PowerSnapshot:
        let rails = power.rails.sorted { $0.key.rawValue < $1.key.rawValue }.map { "\($0.key)=\(number($0.value, "%.2f")) W" }
        return ["live\tpower\t" + rails.joined(separator: " ")]
    case let processes as ProcessSnapshot:
        return ["live\tprocesses\t\(processes.processCount) total, \(processes.inaccessibleCount) inaccessible"]
            + processes.topByCPU.map { "live\t  cpu\t\($0.name)\t\(number($0.cpu * 100, "%.1f"))%\t\($0.memory / 1_048_576) MB" }
    case let wifi as WiFiSnapshot:
        let link = "rssi=\(wifi.rssi ?? 0) noise=\(wifi.noise ?? 0) rate=\(wifi.transmitRate ?? 0)"
        let channel = "ch=\(wifi.channel ?? 0) \(wifi.band) \(wifi.channelWidthMHz ?? 0)MHz \(wifi.phyMode ?? "?")"
        return ["live\twifi\tssid=\(wifi.networkName ?? "hidden") \(link) \(channel)"]
    case let storage as StorageSnapshot:
        let health = storage.ssdHealth.map { "used \($0.percentageUsed)% spare \($0.availableSpare)% written \($0.bytesWritten / 1_000_000_000_000) TB" }
        return ["live\tssd\t\(health ?? "none")"]
    case let network as NetworkSnapshot:
        let active = network.interfaces.filter(\.isActive).map { "\($0.id)(\($0.kind)) in=\($0.totalReceived) out=\($0.totalSent)" }
        return ["live\tnetwork\tdown=\(number(network.downloadRate)) B/s up=\(number(network.uploadRate)) B/s"] + active.map { "live\t  if\t\($0)" }
    default:
        return []
    }
}
