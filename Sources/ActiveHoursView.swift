import AppKit

/// From/To chips for each buddy's active hours; reminders only pop up inside them.
final class ActiveHoursView: NSView {
    private let scheduler: ReminderScheduler
    private(set) var chips: [ReminderKind: (start: ScrollPickerChip, end: ScrollPickerChip)] = [:]
    private var overnightLabels: [ReminderKind: NSTextField] = [:]
    /// Every quarter hour of the day; the chips wrap past midnight for overnight windows.
    static let quarterHours = Array(stride(from: 0, to: 1440, by: 15))

    init(scheduler: ReminderScheduler) {
        self.scheduler = scheduler
        super.init(frame: .zero)
        styleCard(self, radius: 15)
        let heading = label("Active hours", size: 12, weight: .semibold, color: Palette.ink)
        let hint = label("Scroll, drag, or click a time", size: 10, weight: .regular, color: Palette.muted)
        let note = label("Each buddy only nudges inside its hours, every day · saves automatically", size: 10, weight: .regular, color: Palette.muted)
        for view in [heading, hint, note] { addSubview(view) }
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15), heading.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            hint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15), hint.centerYAnchor.constraint(equalTo: heading.centerYAnchor),
            note.leadingAnchor.constraint(equalTo: heading.leadingAnchor), note.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        var previous: NSView = heading
        for kind in ReminderKind.allCases {
            let hours = scheduler.activeHours(for: kind)
            let mascot = MascotDrawingView(kind: kind, frame: .zero)
            let name = label(kind.mascotName, size: 11, weight: .semibold, color: Palette.ink)
            let from = label("From", size: 11, weight: .medium, color: Palette.muted)
            let to = label("to", size: 11, weight: .medium, color: Palette.muted)
            let start = ScrollPickerChip(values: Self.quarterHours, selected: hours.start, wraps: true, tint: kind.color, format: formatMinuteOfDay)
            let end = ScrollPickerChip(values: Self.quarterHours, selected: hours.end, wraps: true, tint: kind.color, format: formatMinuteOfDay)
            // Start and end can never meet, so each window always stays valid while scrolling.
            start.skip = { $0 == end.value }
            end.skip = { $0 == start.value }
            start.setAccessibilityLabel("\(kind.mascotName) start time")
            end.setAccessibilityLabel("\(kind.mascotName) end time")
            start.onChange = { [weak self] _ in self?.save(kind) }
            end.onChange = { [weak self] _ in self?.save(kind) }
            let overnight = label("next day", size: 10, weight: .medium, color: Palette.muted)
            chips[kind] = (start, end)
            overnightLabels[kind] = overnight
            for view in [mascot, name, from, start, to, end, overnight] { addSubview(view) }
            NSLayoutConstraint.activate([
                start.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: previous === heading ? 12 : 6),
                mascot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), mascot.centerYAnchor.constraint(equalTo: start.centerYAnchor),
                mascot.widthAnchor.constraint(equalToConstant: 26), mascot.heightAnchor.constraint(equalToConstant: 26),
                name.leadingAnchor.constraint(equalTo: mascot.trailingAnchor, constant: 7), name.centerYAnchor.constraint(equalTo: start.centerYAnchor),
                from.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 104), from.centerYAnchor.constraint(equalTo: start.centerYAnchor),
                start.leadingAnchor.constraint(equalTo: from.trailingAnchor, constant: 8),
                to.leadingAnchor.constraint(equalTo: start.trailingAnchor, constant: 10), to.centerYAnchor.constraint(equalTo: start.centerYAnchor),
                end.leadingAnchor.constraint(equalTo: to.trailingAnchor, constant: 10), end.centerYAnchor.constraint(equalTo: start.centerYAnchor),
                overnight.leadingAnchor.constraint(equalTo: end.trailingAnchor, constant: 8), overnight.centerYAnchor.constraint(equalTo: start.centerYAnchor)
            ])
            previous = start
            updateOvernight(kind)
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func save(_ kind: ReminderKind) {
        guard let pair = chips[kind] else { return }
        scheduler.setActiveHours(start: pair.start.value, end: pair.end.value, for: kind)
        updateOvernight(kind)
    }

    private func updateOvernight(_ kind: ReminderKind) {
        overnightLabels[kind]?.isHidden = !scheduler.activeHours(for: kind).crossesMidnight
    }
}
