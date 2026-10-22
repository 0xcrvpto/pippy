import AppKit
import QuartzCore

func setTracking(_ field: NSTextField, _ tracking: CGFloat) {
    field.attributedStringValue = NSAttributedString(
        string: field.stringValue,
        attributes: [.font: field.font ?? NSFont.systemFont(ofSize: 10), .foregroundColor: field.textColor ?? Palette.ink, .kern: tracking]
    )
}

func label(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
    let field = NSTextField(labelWithString: text)
    field.translatesAutoresizingMaskIntoConstraints = false
    field.font = NSFont.systemFont(ofSize: size, weight: weight)
    field.textColor = color
    field.lineBreakMode = .byTruncatingTail
    return field
}

func symbol(_ name: String, size: CGFloat, color: NSColor) -> NSImageView {
    let view = NSImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
    view.contentTintColor = color
    view.imageScaling = .scaleProportionallyDown
    return view
}

func button(_ title: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSButton {
    let item = NSButton(title: title, target: nil, action: nil)
    item.translatesAutoresizingMaskIntoConstraints = false
    item.font = NSFont.systemFont(ofSize: size, weight: weight)
    item.contentTintColor = color
    item.isBordered = false
    item.alignment = .center
    return item
}

func symbolButton(_ name: String, color: NSColor) -> NSButton {
    let item = NSButton(image: NSImage(systemSymbolName: name, accessibilityDescription: "Close")!, target: nil, action: nil)
    item.translatesAutoresizingMaskIntoConstraints = false
    item.isBordered = false
    item.contentTintColor = color
    return item
}

func styleCard(_ view: NSView, radius: CGFloat) {
    view.translatesAutoresizingMaskIntoConstraints = false
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.white.cgColor
    view.layer?.cornerRadius = radius
    view.layer?.borderWidth = 1
    view.layer?.borderColor = Palette.line.cgColor
}

private extension NSBezierPath {
    func fillBody(_ color: NSColor) { color.setFill(); fill() }
}

enum Palette {
    static let canvas = NSColor(hex: 0xF7F5F0)
    static let ink = NSColor(hex: 0x25343B)
    static let muted = NSColor(hex: 0x77858A)
    static let line = NSColor(hex: 0xE7E9E5)
    static let coral = NSColor(hex: 0xF19A78)
    static let lilac = NSColor(hex: 0xA8A7EC)
    static let mint = NSColor(hex: 0x83CDB1)
    static let green = NSColor(hex: 0x5FAF8B)
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
