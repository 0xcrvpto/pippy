import AppKit
import QuartzCore

final class MascotDrawingView: NSView {
    var kind: ReminderKind { didSet { needsDisplay = true; animateArrival() } }
    private static var images: [ReminderKind: NSImage] = [:]
    init(kind: ReminderKind, frame: NSRect) {
        self.kind = kind
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.image)
        setAccessibilityLabel("\(kind.mascotName), your \(kind.title.lowercased()) buddy")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); animateArrival() }
    private func animateArrival() {
        layer?.removeAllAnimations()
        guard window != nil, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        let arrival = CAKeyframeAnimation(keyPath: "transform.translation.y")
        arrival.values = kind == .workout ? [-10, 8, -3, 0] : [-5, 3, 0]
        arrival.duration = kind == .workout ? 0.65 : 0.9
        layer?.add(arrival, forKey: "arrival")
        let idle = CABasicAnimation(keyPath: kind == .stretch ? "transform.scale.y" : "transform.rotation.z")
        idle.fromValue = kind == .stretch ? 0.97 : -0.025
        idle.toValue = kind == .stretch ? 1.02 : 0.025
        idle.duration = kind == .eyes ? 3 : 2
        idle.autoreverses = true
        idle.repeatCount = .infinity
        idle.beginTime = CACurrentMediaTime() + 1
        layer?.add(idle, forKey: "idle")
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if Self.images[kind] == nil {
            let name = kind.mascotName
            let bundled = Bundle.main.url(forResource: name, withExtension: "png")
            let local = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets/\(name).png")
            Self.images[kind] = NSImage(contentsOf: bundled ?? local)
        }
        if let image = Self.images[kind] {
            image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
        } else {
            kind.color.setFill()
            NSBezierPath(ovalIn: bounds.insetBy(dx: 5, dy: 5)).fill()
        }
    }
}

final class CompanionReminderView: NSView {
    private let kind: ReminderKind
    private let dismiss: () -> Void
    private let snooze: () -> Void
    private let playCue: (ReminderCue) -> Void
    private var countdown: Timer?
    private var startedAt: Date?
    private var complete = false
    private var halfwayCuePlayed = false
    private var status: NSTextField!
    private var primary: NSButton!
    private var later: NSButton!
    init(kind: ReminderKind, dismiss: @escaping () -> Void, snooze: @escaping () -> Void, soundEnabled: Bool = true, playCue: @escaping (ReminderCue) -> Void) {
        self.kind = kind; self.dismiss = dismiss; self.snooze = snooze; self.playCue = playCue
        let height: CGFloat = kind == .eyes ? 286 : 258
        super.init(frame: NSRect(x: 0, y: 0, width: 350, height: height))
        wantsLayer = true
        let card = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: height - 42))
        card.wantsLayer = true; card.layer?.backgroundColor = Palette.canvas.cgColor
        card.layer?.cornerRadius = 24; card.layer?.borderWidth = 1; card.layer?.borderColor = Palette.line.cgColor
        addSubview(card)
        let buddy = MascotDrawingView(kind: kind, frame: .zero)
        addSubview(buddy)
        let name = label("A LITTLE NUDGE FROM \(kind.mascotName.uppercased())", size: 9, weight: .bold, color: Palette.ink.withAlphaComponent(0.7))
        let headline: String
        let copy: String
        switch kind {
        case .workout: headline = "Time for a little movement?"; copy = "A workout, a walk, or a few stretches.\nMake a little room for yourself."
        case .eyes: headline = "A little rest for your eyes."; copy = soundEnabled ? "Look about 20 feet away for 20 seconds.\nI'll chime when it's time to come back." : "Look about 20 feet away for 20 seconds.\nA quiet little reset, just for you."
        case .stretch: headline = "Let's uncurl a little."; copy = "Roll your shoulders. Stretch your legs.\nA tiny reset can feel pretty good."
        }
        let title = label(headline, size: 19, weight: .bold, color: Palette.ink)
        let message = label(copy, size: 12, weight: .medium, color: Palette.ink.withAlphaComponent(0.8))
        message.maximumNumberOfLines = 2
        status = label("20 seconds · ready when you are", size: 11, weight: .semibold, color: Palette.ink)
        status.isHidden = kind != .eyes
        primary = button(kind == .eyes ? "Start break" : "Got it", size: 13, weight: .semibold, color: .white)
        primary.wantsLayer = true; primary.layer?.backgroundColor = Palette.ink.cgColor; primary.layer?.cornerRadius = 12
        primary.target = self; primary.action = #selector(acknowledge)
        primary.keyEquivalent = "\r"
        later = button("In 10 minutes", size: 12, weight: .medium, color: Palette.ink)
        later.target = self; later.action = #selector(postpone)
        let close = symbolButton("xmark", color: Palette.muted)
        close.target = self; close.action = #selector(closeReminder); close.keyEquivalent = "\u{1b}"
        for v in [name, title, message, status!, primary!, later!, close] { addSubview(v) }
        NSLayoutConstraint.activate([
            buddy.widthAnchor.constraint(equalToConstant: 104), buddy.heightAnchor.constraint(equalToConstant: 104),
            buddy.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15), buddy.topAnchor.constraint(equalTo: topAnchor, constant: -2),
            name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 23), name.topAnchor.constraint(equalTo: topAnchor, constant: 106),
            title.leadingAnchor.constraint(equalTo: name.leadingAnchor), title.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 7),
            message.leadingAnchor.constraint(equalTo: name.leadingAnchor), message.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            status.leadingAnchor.constraint(equalTo: name.leadingAnchor), status.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 8),
            primary.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20), primary.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -17),
            primary.widthAnchor.constraint(equalToConstant: 115), primary.heightAnchor.constraint(equalToConstant: 36),
            later.leadingAnchor.constraint(equalTo: name.leadingAnchor), later.centerYAnchor.constraint(equalTo: primary.centerYAnchor),
            close.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -17), close.topAnchor.constraint(equalTo: topAnchor, constant: 58),
            close.widthAnchor.constraint(equalToConstant: 24), close.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func acknowledge() {
        guard kind == .eyes, !complete else { closeReminder(); return }
        guard startedAt == nil else { return }
        startedAt = Date(); primary.title = "Resting…"; primary.isEnabled = false
        later.isHidden = true; status.stringValue = "20 seconds left · look away"
        playCue(.start)
        countdown = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.advanceBreak() }
    }
    private func advanceBreak() {
        guard let startedAt else { return }
        let seconds = max(0, Int(ceil(20 - Date().timeIntervalSince(startedAt))))
        status.stringValue = "\(seconds) seconds left · look away"
        if seconds > 0 && seconds <= 10 && !halfwayCuePlayed {
            halfwayCuePlayed = true
            playCue(.halfway)
        }
        if seconds == 0 {
            countdown?.invalidate(); countdown = nil; complete = true
            status.stringValue = "Eyes rested. Welcome back!"
            primary.title = "Done"; primary.isEnabled = true; playCue(.complete)
        }
    }
    @objc private func closeReminder() { countdown?.invalidate(); countdown = nil; dismiss() }
    @objc private func postpone() { snooze(); closeReminder() }
    deinit { countdown?.invalidate() }
}
