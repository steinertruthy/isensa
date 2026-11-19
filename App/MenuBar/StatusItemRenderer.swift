import AppKit
import SensaFeatures

/// Draws the menu bar label with AppKit. A template image lets macOS tint it for any menu
/// bar appearance; the drawing handler renders lazily at whatever scale the screen needs.
@MainActor
enum StatusItemRenderer {
    private struct Metrics {
        let font: NSFont
        let symbolSize: CGFloat
        let sparklineSize: NSSize
        let innerSpacing: CGFloat
        let itemSpacing: CGFloat

        static var inline: Metrics { Metrics(
            font: .monospacedDigitSystemFont(ofSize: 12, weight: .medium), symbolSize: 12,
            sparklineSize: NSSize(width: 24, height: 12), innerSpacing: 3, itemSpacing: 8
        ) }
        static var stacked: Metrics { Metrics(
            font: .monospacedDigitSystemFont(ofSize: 9, weight: .semibold), symbolSize: 8,
            sparklineSize: NSSize(width: 16, height: 7), innerSpacing: 2, itemSpacing: 6
        ) }
    }

    private static let height: CGFloat = 22

    static func image(for model: MenuBarLabelModel) -> NSImage {
        guard !model.items.isEmpty else { return fallbackImage() }
        let metrics: Metrics = model.layout == .stacked ? .stacked : .inline
        let columns: [[MenuBarLabelModel.Item]] = model.layout == .stacked
            ? stride(from: 0, to: model.items.count, by: 2).map { Array(model.items[$0..<min($0 + 2, model.items.count)]) }
            : model.items.map { [$0] }
        let widths = columns.map { column in column.map { width(of: $0, metrics) }.max() ?? 0 }
        let totalWidth = ceil(widths.reduce(0, +) + metrics.itemSpacing * CGFloat(max(columns.count - 1, 0)))

        let image = NSImage(size: NSSize(width: max(totalWidth, 1), height: height), flipped: false) { _ in
            var x: CGFloat = 0
            for (column, width) in zip(columns, widths) {
                let rowHeight = height / CGFloat(column.count)
                for (row, item) in column.enumerated() {
                    // Rows are drawn top to bottom.
                    let originY = height - rowHeight * CGFloat(row + 1)
                    draw(item, at: NSPoint(x: x, y: originY), rowHeight: rowHeight, metrics: metrics)
                }
                x += width + metrics.itemSpacing
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = model.items.map(\.text).joined(separator: ", ")
        return image
    }

    private static func fallbackImage() -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: MenuBarLabelModel.fallbackSymbol, accessibilityDescription: "Sensa")?
            .withSymbolConfiguration(configuration) ?? NSImage()
        image.isTemplate = true
        return image
    }

    private static func width(of item: MenuBarLabelModel.Item, _ metrics: Metrics) -> CGFloat {
        var width = attributed(item.text, metrics).size().width
        if item.symbol != nil { width += metrics.symbolSize + metrics.innerSpacing }
        if item.sparkline != nil { width += metrics.sparklineSize.width + metrics.innerSpacing }
        return ceil(width)
    }

    private static func draw(_ item: MenuBarLabelModel.Item, at origin: NSPoint, rowHeight: CGFloat, metrics: Metrics) {
        var x = origin.x
        let midY = origin.y + rowHeight / 2
        if let name = item.symbol, let symbol = symbolImage(name, size: metrics.symbolSize) {
            let size = fitted(symbol.size, into: metrics.symbolSize)
            symbol.draw(in: NSRect(x: x + (metrics.symbolSize - size.width) / 2, y: midY - size.height / 2, width: size.width, height: size.height))
            x += metrics.symbolSize + metrics.innerSpacing
        }
        if let points = item.sparkline {
            drawSparkline(points, in: NSRect(
                x: x, y: midY - metrics.sparklineSize.height / 2,
                width: metrics.sparklineSize.width, height: metrics.sparklineSize.height
            ))
            x += metrics.sparklineSize.width + metrics.innerSpacing
        }
        let text = attributed(item.text, metrics)
        text.draw(at: NSPoint(x: x, y: midY - text.size().height / 2))
    }

    private static func drawSparkline(_ points: [Double], in rect: NSRect) {
        guard points.count > 1 else { return }
        let step = rect.width / CGFloat(points.count - 1)
        let path = NSBezierPath()
        for (index, value) in points.enumerated() {
            let point = NSPoint(x: rect.minX + CGFloat(index) * step, y: rect.minY + CGFloat(value) * rect.height)
            if index == 0 { path.move(to: point) } else { path.line(to: point) }
        }
        let fill = path.copy() as? NSBezierPath ?? NSBezierPath()
        fill.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        fill.line(to: NSPoint(x: rect.minX, y: rect.minY))
        fill.close()
        NSColor.black.withAlphaComponent(0.25).setFill()
        fill.fill()
        NSColor.black.setStroke()
        path.lineWidth = 1.2
        path.lineJoinStyle = .round
        path.stroke()
    }

    private static func attributed(_ text: String, _ metrics: Metrics) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: metrics.font, .foregroundColor: NSColor.black])
    }

    private static func symbolImage(_ name: String, size: CGFloat) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: size, weight: .medium))
    }

    private static func fitted(_ size: NSSize, into side: CGFloat) -> NSSize {
        let scale = min(side / max(size.width, 1), side / max(size.height, 1), 1.2)
        return NSSize(width: size.width * scale, height: size.height * scale)
    }
}
