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
    var defaultSoundSet: SoundSet {
        switch self {
        case .workout: .marimba
        case .eyes: .bells
        case .stretch: .kalimba
        }
    }
    /// Hours each buddy may nudge; Rally's keeps its original storage keys.
    var defaultHours: WorkoutWindow {
        self == .workout ? .standard : WorkoutWindow(start: 11 * 60, end: 23 * 60)!
    }
    var hoursStartKey: String { self == .workout ? "workout.startMinute" : "hours.\(rawValue).start" }
    var hoursEndKey: String { self == .workout ? "workout.endMinute" : "hours.\(rawValue).end" }
    var enabledKey: String { "enabled.\(rawValue)" }
    var soundKey: String { "sound.\(rawValue)" }
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
    private let defaults: UserDefaults
    private let soundPlayer = CuePlayer()
    private let soundKey = "sound.enabled"

    var soundEnabled: Bool {
        defaults.object(forKey: soundKey) as? Bool ?? true
    }

    init(defaults: UserDefaults = .standard, startTimer: Bool = true) {
        self.defaults = defaults
        for kind in ReminderKind.allCases {
            let enabled = defaults.object(forKey: kind.enabledKey) as? Bool ?? true
            let minutes = defaults.object(forKey: kind.minutesKey) as? Int ?? kind.initialMinutes
            settings[kind] = ReminderSettings(enabled: enabled, minutes: minutes)
            if defaults.object(forKey: kind.lastFireKey) == nil {
                defaults.set(Date(), forKey: kind.lastFireKey)
            }
        }
        if startTimer {
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.checkSchedule() }
        }
    }

    func value(for kind: ReminderKind) -> ReminderSettings {
        settings[kind] ?? ReminderSettings(enabled: true, minutes: kind.initialMinutes)
    }

    func setEnabled(_ enabled: Bool, for kind: ReminderKind) {
        var next = value(for: kind)
        next.enabled = enabled
        settings[kind] = next
        defaults.set(enabled, forKey: kind.enabledKey)
        defaults.set(Date(), forKey: kind.lastFireKey)
        NotificationCenter.default.post(name: .pippySettingsChanged, object: self)
    }

    var enabledCount: Int { ReminderKind.allCases.filter { value(for: $0).enabled }.count }

    func setMinutes(_ minutes: Int, for kind: ReminderKind) {
        var next = value(for: kind)
        next.minutes = min(max(minutes, kind.range.lowerBound), kind.range.upperBound)
        settings[kind] = next
        defaults.set(next.minutes, forKey: kind.minutesKey)
        NotificationCenter.default.post(name: .pippySettingsChanged, object: self)
        defaults.set(Date(), forKey: kind.lastFireKey)
    }

    func setSoundEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: soundKey)
    }

    func soundSet(for kind: ReminderKind) -> SoundSet {
        defaults.string(forKey: kind.soundKey).flatMap(SoundSet.init(rawValue:)) ?? kind.defaultSoundSet
    }

    func setSoundSet(_ set: SoundSet, for kind: ReminderKind) {
        defaults.set(set.rawValue, forKey: kind.soundKey)
    }

    func preview(_ kind: ReminderKind) { deliver(kind) }

    func activeHours(for kind: ReminderKind) -> WorkoutWindow {
        guard let start = defaults.object(forKey: kind.hoursStartKey) as? Int,
              let end = defaults.object(forKey: kind.hoursEndKey) as? Int else { return kind.defaultHours }
        return WorkoutWindow(start: start, end: end) ?? kind.defaultHours
    }

    @discardableResult
    func setActiveHours(start: Int, end: Int, for kind: ReminderKind) -> Bool {
        guard let window = WorkoutWindow(start: start, end: end) else { return false }
        defaults.set(window.start, forKey: kind.hoursStartKey)
        defaults.set(window.end, forKey: kind.hoursEndKey)
        NotificationCenter.default.post(name: .pippySettingsChanged, object: self)
        return true
    }

    var workoutWindow: WorkoutWindow { activeHours(for: .workout) }

    @discardableResult
    func setWorkoutWindow(start: Int, end: Int) -> Bool { setActiveHours(start: start, end: end, for: .workout) }

    func playCue(_ cue: ReminderCue, for kind: ReminderKind) {
        guard soundEnabled else { return }
        soundPlayer.play(cue, in: soundSet(for: kind))
    }

    /// Explicit previews play even when reminder sounds are muted.
    func previewSound(for kind: ReminderKind) {
        soundPlayer.preview(soundSet(for: kind), fullSequence: kind == .eyes)
    }

    deinit { timer?.invalidate() }

    private func deliver(_ kind: ReminderKind) {
        if kind != .eyes { playCue(.nudge, for: kind) }
        panelManager.show(kind, snooze: { [weak self] in
            self?.snoozedUntil[kind] = Date().addingTimeInterval(600)
        }, soundEnabled: { [weak self] in self?.soundEnabled ?? false }, playCue: { [weak self] cue in
            self?.playCue(cue, for: kind)
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
            if kind != .workout, !activeHours(for: kind).contains(minute: minuteOfDay(now)) { continue }
            if kind == .workout {
                guard workoutSlotIsDue(now: now, interval: config.minutes) else { continue }
                deliver(kind)
                return
            }
            let last = defaults.object(forKey: kind.lastFireKey) as? Date ?? now
            guard now.timeIntervalSince(last) >= Double(config.minutes * 60) else { continue }
            defaults.set(now, forKey: kind.lastFireKey)
            deliver(kind)
            return
        }
    }

    private func minuteOfDay(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    private func workoutSlotIsDue(now: Date, interval: Int) -> Bool {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        guard let hour = parts.hour, let minute = parts.minute else { return false }
        let minuteOfDay = hour * 60 + minute
        guard workoutWindow.isSlot(minute: minuteOfDay, interval: interval) else { return false }
        let day = "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
        let slot = "\(day)-\(minuteOfDay)"
        let key = "workout.lastSlot"
        guard defaults.string(forKey: key) != slot else { return false }
        defaults.set(slot, forKey: key)
        return true
    }
}
