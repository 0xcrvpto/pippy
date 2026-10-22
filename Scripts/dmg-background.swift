import AppKit

/// Renders the installer window background at 1x and 2x: Pippy on the left, Applications on the right.
@main struct DMGBackground {
    static func main() {
        let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".build")
        let ink = NSColor(calibratedRed: 0x25/255, green: 0x34/255, blue: 0x3B/255, alpha: 1)
        let muted = NSColor(calibratedRed: 0x77/255, green: 0x85/255, blue: 0x8A/255, alpha: 1)
        let coral = NSColor(calibratedRed: 0xF1/255, green: 0x9A/255, blue: 0x78/255, alpha: 1)
        let canvas = NSColor(calibratedRed: 0xF7/255, green: 0xF5/255, blue: 0xF0/255, alpha: 1)
        for scale in [1, 2] {
            let size = NSSize(width: 600, height: 400)
            guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale, pixelsHigh: Int(size.height) * scale,
                                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                             colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else { fatalError("bitmap") }
            rep.size = size
            NSGraphicsContext.saveGraphicsState()
            // A flipped context keeps text upright while coordinates run top-down like Finder's.
            NSGraphicsContext.current = NSGraphicsContext(cgContext: NSGraphicsContext(bitmapImageRep: rep)!.cgContext, flipped: true)
            // Finder places icon centres at (150, 190) and (450, 190) from the top-left.
            let flip = NSAffineTransform(); flip.translateX(by: 0, yBy: size.height); flip.scaleX(by: 1, yBy: -1); flip.concat()
            canvas.setFill(); NSRect(origin: .zero, size: size).fill()
            for (x, alpha) in [(150.0, 0.16), (450.0, 0.10)] {
                coral.withAlphaComponent(alpha).setFill()
                NSBezierPath(roundedRect: NSRect(x: x - 82, y: 108, width: 164, height: 176), xRadius: 30, yRadius: 30).fill()
            }
            let arrow = NSBezierPath()
            arrow.move(to: NSPoint(x: 252, y: 180)); arrow.line(to: NSPoint(x: 340, y: 180))
            arrow.move(to: NSPoint(x: 328, y: 168)); arrow.line(to: NSPoint(x: 344, y: 180)); arrow.line(to: NSPoint(x: 328, y: 192))
            arrow.lineWidth = 5; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round
            ink.withAlphaComponent(0.55).setStroke(); arrow.stroke()
            func centered(_ text: String, y: CGFloat, size points: CGFloat, weight: NSFont.Weight, color: NSColor) {
                let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: points, weight: weight), .foregroundColor: color]
                let width = (text as NSString).size(withAttributes: attributes).width
                (text as NSString).draw(at: NSPoint(x: (size.width - width) / 2, y: y), withAttributes: attributes)
            }
            centered("Drag Pippy into Applications", y: 36, size: 20, weight: .bold, color: ink)
            centered("Then open Pippy from your Applications folder.", y: 66, size: 12, weight: .medium, color: muted)
            centered("Unsigned early release: if macOS blocks it, open System Settings › Privacy & Security › Open Anyway.",
                     y: 330, size: 10, weight: .regular, color: muted)
            NSGraphicsContext.restoreGraphicsState()
            let name = scale == 1 ? "background.png" : "background@2x.png"
            try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
        }
    }
}
