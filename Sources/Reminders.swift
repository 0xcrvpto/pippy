import AppKit
import QuartzCore

enum ReminderKind: String, CaseIterable {
    case workout, eyes, stretch

    var title: String {
        switch self {
        case .workout: "Workout"
        case .eyes: "Eye break"
        case .stretch: "Stretch & move"
        }
    }
    var mascotName: String {
        switch self {
        case .workout: "Rally"
        case .eyes: "Blink"
        case .stretch: "Mochi"
        }
    }
    var tagline: String {
        switch self {
        case .workout: "A little gym-time nudge"
        case .eyes: "20-20-20 screen reset"
        case .stretch: "Uncurl and move a little"
        }
    }
    var message: String {
        switch self {
        case .workout: "Gym time, if you're up for it. Your future self says thanks!"
        case .eyes: "Look at something 20 feet away for 20 seconds. I've got the screen."
        case .stretch: "Shoulders back, legs awake. Let's take a tiny movement break."
        }
    }
    var buttonTitle: String {
        switch self {
        case .workout: "Let's go"
        case .eyes: "Eyes rested"
        case .stretch: "All stretched"
        }
    }
    var icon: String {
        switch self {
        case .workout: "figure.run"
        case .eyes: "eye"
        case .stretch: "figure.cooldown"
        }
    }
    var color: NSColor {
        switch self {
        case .workout: Palette.coral
        case .eyes: Palette.lilac
        case .stretch: Palette.mint
        }
    }
    var initialMinutes: Int {
        switch self {
        case .workout: 60
        case .eyes: 20
        case .stretch: 45
        }
    }
    var range: ClosedRange<Int> {
        switch self {
        case .workout: 30...240
        case .eyes: 5...60
        case .stretch: 15...120
        }
    }
    var step: Int {
        switch self {
        case .workout: 30
        case .eyes: 5
        case .stretch: 15
        }
    }
    var enabledKey: String { "enabled.\(rawValue)" }
    var minutesKey: String { "minutes.\(rawValue)" }
    var lastFireKey: String { "lastFire.\(rawValue)" }
}

struct ReminderSettings {
    var enabled: Bool
    var minutes: Int
}

final class ReminderScheduler {
    private(set) var settings: [ReminderKind: ReminderSettings] = [:]
    private let panelManager = FloatingPanelManager()
    private var timer: Timer?
    private var snoozedUntil: [ReminderKind: Date] = [:]
    private let soundKey = "sound.enabled"

    var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true
    }

    init() {
        let defaults = UserDefaults.standard
        for kind in ReminderKind.allCases {
            let enabled = defaults.object(forKey: kind.enabledKey) as? Bool ?? true
            let minutes = defaults.object(forKey: kind.minutesKey) as? Int ?? kind.initialMinutes
            settings[kind] = ReminderSettings(enabled: enabled, minutes: minutes)
            if defaults.object(forKey: kind.lastFireKey) == nil {
                defaults.set(Date(), forKey: kind.lastFireKey)
            }
        }
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkSchedule), userInfo: nil, repeats: true)
    }

    func value(for kind: ReminderKind) -> ReminderSettings {
        settings[kind] ?? ReminderSettings(enabled: true, minutes: kind.initialMinutes)
    }

    func setEnabled(_ enabled: Bool, for kind: ReminderKind) {
        var next = value(for: kind)
        next.enabled = enabled
        settings[kind] = next
        UserDefaults.standard.set(enabled, forKey: kind.enabledKey)
        UserDefaults.standard.set(Date(), forKey: kind.lastFireKey)
    }

    func setMinutes(_ minutes: Int, for kind: ReminderKind) {
        var next = value(for: kind)
        next.minutes = min(max(minutes, kind.range.lowerBound), kind.range.upperBound)
        settings[kind] = next
        UserDefaults.standard.set(next.minutes, forKey: kind.minutesKey)
        UserDefaults.standard.set(Date(), forKey: kind.lastFireKey)
    }

    func setSoundEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: soundKey)
    }

    func preview(_ kind: ReminderKind) { deliver(kind) }

    func playCue(completed: Bool) {
        guard soundEnabled else { return }
        let soundName = completed ? "Glass" : "Tink"
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.volume = 0.28
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func deliver(_ kind: ReminderKind) {
        if kind != .eyes && soundEnabled { playCue(completed: false) }
        panelManager.show(kind, snooze: { [weak self] in
            self?.snoozedUntil[kind] = Date().addingTimeInterval(600)
        }, soundEnabled: { [weak self] in self?.soundEnabled ?? false }, playCue: { [weak self] completed in
            self?.playCue(completed: completed)
        })
    }

    @objc private func checkSchedule() {
        let now = Date()
        for kind in ReminderKind.allCases {
            let config = value(for: kind)
            guard config.enabled else { continue }
            if let due = snoozedUntil[kind] {
                guard now >= due else { continue }
                snoozedUntil.removeValue(forKey: kind)
                deliver(kind)
                return
            }
            if kind != .workout, !isReminderDaytime(now) { continue }
            if kind == .workout {
                guard workoutSlotIsDue(now: now, interval: config.minutes) else { continue }
                deliver(kind)
                return
            }
            let last = UserDefaults.standard.object(forKey: kind.lastFireKey) as? Date ?? now
            guard now.timeIntervalSince(last) >= Double(config.minutes * 60) else { continue }
            UserDefaults.standard.set(now, forKey: kind.lastFireKey)
            deliver(kind)
            return
        }
    }

    private func isReminderDaytime(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 11 && hour < 23
    }

    private func workoutSlotIsDue(now: Date, interval: Int) -> Bool {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        guard let hour = parts.hour, let minute = parts.minute, let second = parts.second else { return false }
        let minuteOfDay = hour * 60 + minute
        let start = 14 * 60
        let end = 18 * 60
        guard minuteOfDay >= start, minuteOfDay < end,
              (minuteOfDay - start) % interval == 0, second < 20 else { return false }
        let day = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        let slot = "\(day)-\(minuteOfDay)"
        let key = "workout.lastSlot"
        guard UserDefaults.standard.string(forKey: key) != slot else { return false }
        UserDefaults.standard.set(slot, forKey: key)
        return true
    }
}

