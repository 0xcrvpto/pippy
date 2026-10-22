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

/// A borderless, layer-filled button with a hover tint and a pointing-hand cursor.
final class PillButton: NSButton {
    private let fill: NSColor
    private let hoverFill: NSColor
    private let radius: CGFloat?
    private var tracking: NSTrackingArea?
    private var hovering = false { didSet { refreshFill() } }

    init(title: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, fill: NSColor, hoverFill: NSColor, radius: CGFloat? = nil) {
        self.fill = fill
        self.hoverFill = hoverFill
        self.radius = radius
        super.init(frame: .zero)
        self.title = title
        translatesAutoresizingMaskIntoConstraints = false
        font = NSFont.systemFont(ofSize: size, weight: weight)
        contentTintColor = color
        attributedTitle = NSAttributedString(string: title, attributes: [.font: font!, .foregroundColor: color])
        isBordered = false
        alignment = .center
        wantsLayer = true
        refreshFill()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var title: String {
        didSet {
            guard let font, let color = contentTintColor else { return }
            attributedTitle = NSAttributedString(string: title, attributes: [.font: font, .foregroundColor: color])
        }
    }
    override var intrinsicContentSize: NSSize {
        let base = super.intrinsicContentSize
        return NSSize(width: base.width + 22, height: max(base.height, 24))
    }
    override func layout() {
        super.layout()
        layer?.cornerRadius = radius ?? bounds.height / 2
    }
    private func refreshFill() {
        layer?.backgroundColor = (hovering && isEnabled ? hoverFill : fill).cgColor
    }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }
    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}

/// Soft white pill used for secondary actions on the cream canvas.
func softPill(_ title: String, size: CGFloat = 10) -> PillButton {
    PillButton(title: title, size: size, weight: .semibold, color: Palette.ink,
               fill: NSColor.white.withAlphaComponent(0.85), hoverFill: NSColor.white)
}

/// Dark primary action.
func inkPill(_ title: String, size: CGFloat = 12, radius: CGFloat = 11) -> PillButton {
    PillButton(title: title, size: size, weight: .semibold, color: .white,
               fill: Palette.ink, hoverFill: Palette.ink.blended(withFraction: 0.18, of: .white) ?? Palette.ink, radius: radius)
}

/// A rounded tag such as "2:00 PM–6:00 PM", with its text centred in a tinted capsule.
final class TagView: NSView {
    let text: NSTextField
    init(_ string: String, tint: NSColor) {
        text = label(string, size: 10, weight: .bold, color: Palette.ink)
        text.alignment = .center
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = tint.withAlphaComponent(0.2).cgColor
        layer?.cornerRadius = 11
        addSubview(text)
        NSLayoutConstraint.activate([
            text.centerYAnchor.constraint(equalTo: centerYAnchor),
            text.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            text.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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
