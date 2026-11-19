// sensa-probe — development tool that dumps every sensor Sensa can see on this Mac.
// Used to validate the sensor catalog (idle vs. load) before marking mappings as verified.
//
// Usage: sensa-probe [smc|hid|all] [prefixes...]
//   sensa-probe smc T F P     → SMC keys starting with T, F or P with their decoded values
import Foundation
import SensaHardware
import SensaPrivateAPI

let arguments = CommandLine.arguments.dropFirst()
let mode = arguments.first ?? "all"
let prefixes = Array(arguments.dropFirst())

func line(_ text: String) { FileHandle.standardOutput.write(Data((text + "\n").utf8)) }

line("# model \(Sysctl.string("hw.model") ?? "?") · \(Sysctl.string("machdep.cpu.brand_string") ?? "?")")

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
