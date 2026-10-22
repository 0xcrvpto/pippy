import AppKit

final class WorkoutHoursView: NSView {
    private let scheduler: ReminderScheduler
    private let startPicker = NSDatePicker()
    private let endPicker = NSDatePicker()
    private let note = NSTextField(labelWithString: "")

    init(scheduler: ReminderScheduler) {
        self.scheduler = scheduler
        super.init(frame: .zero)
        styleCard(self, radius: 15)
        let heading = label("Rally's workout hours", size: 12, weight: .semibold, color: Palette.ink)
        let from = label("From", size: 11, weight: .medium, color: Palette.ink)
        let to = label("to", size: 11, weight: .medium, color: Palette.ink)
        for (picker, minute, name) in [(startPicker, scheduler.workoutWindow.start, "Workout start time"), (endPicker, scheduler.workoutWindow.end, "Workout end time")] {
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.datePickerElements = .hourMinute
            picker.datePickerStyle = .textFieldAndStepper
            picker.dateValue = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: minute / 60, minute: minute % 60))!
            picker.setAccessibilityLabel(name)
            picker.target = self
            picker.action = #selector(changeHours)
        }
        note.translatesAutoresizingMaskIntoConstraints = false
        note.font = .systemFont(ofSize: 10)
        for view in [heading, from, startPicker, to, endPicker, note] { addSubview(view) }
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15), heading.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            from.leadingAnchor.constraint(equalTo: heading.leadingAnchor), from.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 13),
            startPicker.leadingAnchor.constraint(equalTo: from.trailingAnchor, constant: 12), startPicker.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            startPicker.widthAnchor.constraint(equalToConstant: 115),
            to.leadingAnchor.constraint(equalTo: startPicker.trailingAnchor, constant: 20), to.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            endPicker.leadingAnchor.constraint(equalTo: to.trailingAnchor, constant: 12), endPicker.centerYAnchor.constraint(equalTo: from.centerYAnchor),
            endPicker.widthAnchor.constraint(equalToConstant: 115),
            note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        updateNote()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func changeHours() {
        func minutes(_ picker: NSDatePicker) -> Int {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: picker.dateValue)
            return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
        guard scheduler.setWorkoutWindow(start: minutes(startPicker), end: minutes(endPicker)) else {
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
