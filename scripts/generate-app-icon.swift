// Renders iSensa's app icon at every size required by the asset catalog.
// Usage: swift scripts/generate-app-icon.swift App/Resources/Assets.xcassets/AppIcon.appiconset
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])

func render(size: Int) -> Data {
    let s = CGFloat(size)
    // Explicit pixel dimensions: NSImage.lockFocus would render at the screen's backing scale.
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let unit = s / 1024

    // macOS icon grid: 824 pt body centred in a 1024 canvas.
    let body = CGRect(x: 100 * unit, y: 100 * unit, width: 824 * unit, height: 824 * unit)
    let shape = CGPath(roundedRect: body, cornerWidth: 186 * unit, cornerHeight: 186 * unit, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * unit), blur: 24 * unit, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(shape)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    let background = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.16, green: 0.20, blue: 0.29, alpha: 1).cgColor,
        NSColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(background, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
    // Soft top highlight.
    let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor.white.withAlphaComponent(0.10).cgColor, NSColor.white.withAlphaComponent(0).cgColor
    ] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: body.midX, y: body.maxY), startRadius: 0,
                           endCenter: CGPoint(x: body.midX, y: body.maxY), endRadius: 520 * unit, options: [])

    // Gauge.
    let center = CGPoint(x: body.midX, y: body.midY - 20 * unit)
    let radius = 270 * unit
    let width = 64 * unit
    let start = CGFloat.pi * 1.25, end = -CGFloat.pi * 0.25
    ctx.setLineCap(.round)
    ctx.setLineWidth(width)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.10).cgColor)
    ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    ctx.strokePath()

    let activeEnd = start - (start - end) * 0.68
    ctx.saveGState()
    ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: activeEnd, clockwise: true)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    let arcGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.30, green: 0.86, blue: 0.95, alpha: 1).cgColor,
        NSColor(red: 0.04, green: 0.52, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.55, green: 0.38, blue: 1.00, alpha: 1).cgColor
    ] as CFArray, locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(arcGradient, start: CGPoint(x: center.x - radius, y: center.y - radius),
                           end: CGPoint(x: center.x + radius * 0.4, y: center.y + radius), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()

    // Centre pulse dot.
    let dot = 46 * unit
    ctx.setShadow(offset: .zero, blur: 40 * unit, color: NSColor(red: 0.2, green: 0.6, blue: 1, alpha: 0.9).cgColor)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillEllipse(in: CGRect(x: center.x - dot / 2, y: center.y - dot / 2, width: dot, height: dot))
    ctx.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try render(size: pixels).write(to: output.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))
