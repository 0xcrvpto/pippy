import AppKit

final class WorkoutHoursView: NSView {
    private let scheduler: ReminderScheduler
    private(set) var startChip: ScrollPickerChip!
    private(set) var endChip: ScrollPickerChip!
    private let note = NSTextField(labelWithString: "")
    /// Every quarter hour of the day; the chips wrap past midnight for overnight windows.
    static let quarterHours = Array(stride(from: 0, to: 1440, by: 15))

    init(scheduler: ReminderScheduler) {
        self.scheduler = scheduler
        super.init(frame: .zero)
        styleCard(self, radius: 15)
        let heading = label("Rally's workout hours", size: 12, weight: .semibold, color: Palette.ink)
        let hint = label("Scroll, drag, or click a time", size: 10, weight: .regular, color: Palette.muted)
        let from = label("From", size: 11, weight: .medium, color: Palette.ink)
        let to = label("to", size: 11, weight: .medium, color: Palette.ink)
        let window = scheduler.workoutWindow
        startChip = ScrollPickerChip(values: Self.quarterHours, selected: window.start, wraps: true, tint: Palette.coral, format: formatMinuteOfDay)
        endChip = ScrollPickerChip(values: Self.quarterHours, selected: window.end, wraps: true, tint: Palette.coral, format: formatMinuteOfDay)
        // Start and end can never meet, so the window always stays valid while scrolling.
        startChip.skip = { [unowned self] in $0 == self.endChip.value }
        endChip.skip = { [unowned self] in $0 == self.startChip.value }
        startChip.setAccessibilityLabel("Workout start time")
        endChip.setAccessibilityLabel("Workout end time")
        startChip.onChange = { [weak self] _ in self?.changeHours() }
        endChip.onChange = { [weak self] _ in self?.changeHours() }
        note.translatesAutoresizingMaskIntoConstraints = false
        note.font = .systemFont(ofSize: 10)
        for view in [heading, hint, from, startChip!, to, endChip!, note] { addSubview(view) }
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15), heading.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            hint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15), hint.centerYAnchor.constraint(equalTo: heading.centerYAnchor),
            from.leadingAnchor.constraint(equalTo: heading.leadingAnchor), from.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 15),
            startChip.leadingAnchor.constraint(equalTo: from.trailingAnchor, constant: 10), startChip.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            to.leadingAnchor.constraint(equalTo: startChip.trailingAnchor, constant: 10), to.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            endChip.leadingAnchor.constraint(equalTo: to.trailingAnchor, constant: 10), endChip.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        updateNote()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func changeHours() {
        guard scheduler.setWorkoutWindow(start: startChip.value, end: endChip.value) else {
            note.stringValue = "Choose different start and end times. Your previous hours are saved."
            note.textColor = .systemRed
            return
        }
        updateNote()
    }
    private func updateNote() {
        note.textColor = Palette.muted
        note.stringValue = scheduler.workoutWindow.crossesMidnight
            ? "Every day · ends the following morning · saves automatically"
            : "Every day · reminders repeat at your chosen interval · saves automatically"
    }
}
