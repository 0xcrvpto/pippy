import AppKit

/// A compact value chip: scroll, drag vertically, use the arrow keys, or click for a menu.
final class ScrollPickerChip: NSView {
    let values: [Int]
    private let format: (Int) -> String
    private let wraps: Bool
    private let tint: NSColor
    private(set) var index: Int
    /// Values the chip steps over, such as a workout end that would equal its start.
    var skip: (Int) -> Bool = { _ in false }
    var onChange: (Int) -> Void = { _ in }
    private var scrollAccumulator: CGFloat = 0
    private var hovering = false { didSet { needsDisplay = true } }
    private var tracking: NSTrackingArea?

    var value: Int { values[index] }

    init(values: [Int], selected: Int, wraps: Bool, tint: NSColor, format: @escaping (Int) -> String) {
        precondition(!values.isEmpty)
        self.values = values
        self.format = format
        self.wraps = wraps
        self.tint = tint
        index = values.firstIndex(of: selected) ?? values.indices.min { abs(values[$0] - selected) < abs(values[$1] - selected) }!
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setAccessibilityElement(true)
        setAccessibilityRole(.incrementor)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() { NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2).fill() }

    private var textAttributes: [NSAttributedString.Key: Any] {
        [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold), .foregroundColor: Palette.ink]
    }

    override var intrinsicContentSize: NSSize {
        let widest = values.map { (format($0) as NSString).size(withAttributes: textAttributes).width }.max() ?? 40
        return NSSize(width: ceil(widest) + 38, height: 26)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        tint.withAlphaComponent(hovering ? 0.30 : 0.17).setFill()
        path.fill()
        let text = format(value) as NSString
        let size = text.size(withAttributes: textAttributes)
        text.draw(at: NSPoint(x: 12, y: (bounds.height - size.height) / 2), withAttributes: textAttributes)
        if let chevron = NSImage(systemSymbolName: "chevron.up.chevron.down", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 9, weight: .bold)) {
            let tinted = NSImage(size: chevron.size, flipped: false) { rect in
                chevron.draw(in: rect)
                Palette.ink.withAlphaComponent(0.55).set()
                rect.fill(using: .sourceAtop)
                return true
            }
            tinted.draw(in: NSRect(x: bounds.width - 12 - chevron.size.width, y: (bounds.height - chevron.size.height) / 2,
                                   width: chevron.size.width, height: chevron.size.height))
        }
    }

    // MARK: Changing the value

    func select(_ newValue: Int) {
        guard let found = values.firstIndex(of: newValue) else { return }
        index = found
        needsDisplay = true
    }

    /// Moves by `delta` steps, skipping excluded values; returns whether the value changed.
    @discardableResult
    func step(by delta: Int) -> Bool {
        guard delta != 0 else { return false }
        let direction = delta > 0 ? 1 : -1
        var candidate = index
        var remaining = abs(delta)
        for _ in 0..<(values.count * 2) where remaining > 0 {
            var next = candidate + direction
            if wraps { next = (next + values.count) % values.count }
            guard values.indices.contains(next) else { break }
            candidate = next
            if !skip(values[candidate]) { remaining -= 1 }
        }
        guard candidate != index, !skip(values[candidate]) else { return false }
        index = candidate
        needsDisplay = true
        onChange(value)
        return true
    }

    override func scrollWheel(with event: NSEvent) {
        // Trackpads report fine-grained deltas; a mouse wheel moves one step per notch.
        let delta = event.scrollingDeltaY * (event.isDirectionInvertedFromDevice ? -1 : 1)
        if event.hasPreciseScrollingDeltas {
            scrollAccumulator += delta
            let steps = Int(scrollAccumulator / 14)
            if steps != 0 { scrollAccumulator -= CGFloat(steps) * 14; step(by: steps) }
        } else if delta != 0 {
            step(by: delta > 0 ? 1 : -1)
        }
        if event.phase == .ended || event.momentumPhase == .ended { scrollAccumulator = 0 }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let origin = event.locationInWindow
        var dragged = false
        var lastStepY = origin.y
        while let next = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
            if next.type == .leftMouseUp { break }
            let y = next.locationInWindow.y
            if abs(y - origin.y) > 3 { dragged = true }
            // Dragging up increases the value, about one step per 8 points.
            let steps = Int((y - lastStepY) / 8)
            if steps != 0 { lastStepY += CGFloat(steps) * 8; step(by: steps) }
        }
        if !dragged { showMenu() }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126, 124: step(by: 1)
        case 125, 123: step(by: -1)
        case 36, 49: showMenu()
        default: super.keyDown(with: event)
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        var current: NSMenuItem?
        for (offset, item) in values.enumerated() where !skip(item) || offset == index {
            let entry = NSMenuItem(title: format(item), action: #selector(pick(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = offset
            if offset == index { entry.state = .on; current = entry }
            menu.addItem(entry)
        }
        menu.popUp(positioning: current, at: NSPoint(x: 4, y: bounds.height - 4), in: self)
    }

    @objc private func pick(_ sender: NSMenuItem) {
        guard sender.tag != index else { return }
        index = sender.tag
        needsDisplay = true
        onChange(value)
    }

    // MARK: Hover and cursor

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

    // MARK: Accessibility

    override func accessibilityValue() -> Any? { format(value) }
    override func accessibilityPerformIncrement() -> Bool { step(by: 1); return true }
    override func accessibilityPerformDecrement() -> Bool { step(by: -1); return true }
}

/// "2:00 PM" for a minute of the day, in the user's locale.
func formatMinuteOfDay(_ minute: Int) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter.string(from: Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: minute / 60, minute: minute % 60))!)
}
