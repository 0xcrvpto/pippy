import AppKit
import QuartzCore

final class DashboardView: NSView {
    private let scheduler: ReminderScheduler
    private var selectedKind: ReminderKind = .stretch
    private var previewCard: NSView!
    private var mascotPreview: MascotDrawingView!
    private var previewName: NSTextField!
    private var previewType: NSTextField!
    private var selectorButtons: [ReminderKind: NSButton] = [:]

    init(scheduler: ReminderScheduler, frame: NSRect) {
        self.scheduler = scheduler
        super.init(frame: frame)
        wantsLayer = true
        autoresizingMask = [.width, .height]
        layer?.backgroundColor = Palette.canvas.cgColor
        buildHeader()
        buildLeftColumn()
        buildRightColumn()
        buildFooter()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildHeader() {
        let iconTile = NSView()
        iconTile.translatesAutoresizingMaskIntoConstraints = false
        iconTile.wantsLayer = true
        iconTile.layer?.backgroundColor = Palette.ink.cgColor
        iconTile.layer?.cornerRadius = 10
        let paw = symbol("pawprint.fill", size: 15, color: .white)
        iconTile.addSubview(paw)
        NSLayoutConstraint.activate([
            iconTile.widthAnchor.constraint(equalToConstant: 34), iconTile.heightAnchor.constraint(equalToConstant: 34),
            paw.centerXAnchor.constraint(equalTo: iconTile.centerXAnchor), paw.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor)
        ])
        addSubview(iconTile)

        let pip = label("PIPPY", size: 13, weight: .heavy, color: Palette.ink)
        setTracking(pip, 1.6)
        addSubview(pip)
        let subtitle = label("LITTLE CHECK-INS", size: 10, weight: .semibold, color: Palette.muted)
        setTracking(subtitle, 1.1)
        addSubview(subtitle)

        let status = NSView()
        status.translatesAutoresizingMaskIntoConstraints = false
        status.wantsLayer = true
        status.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.8).cgColor
        status.layer?.cornerRadius = 13
        let dot = NSView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.wantsLayer = true
        dot.layer?.backgroundColor = Palette.green.cgColor
        dot.layer?.cornerRadius = 3.5
        status.addSubview(dot)
        let ready = label("READY ON THIS MAC", size: 9, weight: .bold, color: Palette.ink.withAlphaComponent(0.72))
        setTracking(ready, 0.7)
        status.addSubview(ready)
        addSubview(status)

        let preferences = button("⚙  Preferences", size: 10, weight: .semibold, color: Palette.ink)
        preferences.wantsLayer = true
        preferences.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.8).cgColor
        preferences.layer?.cornerRadius = 13
        preferences.target = NSApp.delegate
        preferences.action = #selector(AppDelegate.openPreferences)
        addSubview(preferences)
        NSLayoutConstraint.activate([
            iconTile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), iconTile.topAnchor.constraint(equalTo: topAnchor, constant: 23),
            pip.leadingAnchor.constraint(equalTo: iconTile.trailingAnchor, constant: 9), pip.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            subtitle.leadingAnchor.constraint(equalTo: pip.trailingAnchor, constant: 12), subtitle.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            status.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30), status.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            status.heightAnchor.constraint(equalToConstant: 27), status.widthAnchor.constraint(equalToConstant: 151),
            preferences.trailingAnchor.constraint(equalTo: status.leadingAnchor, constant: -10), preferences.centerYAnchor.constraint(equalTo: status.centerYAnchor),
            preferences.widthAnchor.constraint(equalToConstant: 96), preferences.heightAnchor.constraint(equalToConstant: 27),
            dot.leadingAnchor.constraint(equalTo: status.leadingAnchor, constant: 11), dot.centerYAnchor.constraint(equalTo: status.centerYAnchor), dot.widthAnchor.constraint(equalToConstant: 7), dot.heightAnchor.constraint(equalToConstant: 7),
            ready.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 7), ready.centerYAnchor.constraint(equalTo: status.centerYAnchor)
        ])
    }

    private func buildLeftColumn() {
        let headline = label("A little nudge,\nright on time.", size: 34, weight: .bold, color: Palette.ink)
        headline.maximumNumberOfLines = 2
        headline.lineBreakMode = .byWordWrapping
        headline.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(headline)
        let supporting = label("Three tiny desk buddies to help your day feel better.", size: 12, weight: .regular, color: Palette.muted)
        addSubview(supporting)

        NSLayoutConstraint.activate([
            headline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), headline.topAnchor.constraint(equalTo: topAnchor, constant: 82),
            supporting.leadingAnchor.constraint(equalTo: headline.leadingAnchor), supporting.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 7)
        ])

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.distribution = .fillEqually
        rows.spacing = 10
        rows.translatesAutoresizingMaskIntoConstraints = false
        for kind in ReminderKind.allCases {
            let row = ReminderRowView(kind: kind, scheduler: scheduler)
            row.widthAnchor.constraint(equalToConstant: 570).isActive = true
            row.heightAnchor.constraint(equalToConstant: 102).isActive = true
            rows.addArrangedSubview(row)
        }
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            rows.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -350),
            rows.topAnchor.constraint(equalTo: topAnchor, constant: 192)
        ])
    }

    private func buildRightColumn() {
        previewCard = NSView()
        styleCard(previewCard, radius: 22)
        addSubview(previewCard)
        NSLayoutConstraint.activate([
            previewCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            previewCard.topAnchor.constraint(equalTo: topAnchor, constant: 82),
            previewCard.widthAnchor.constraint(equalToConstant: 300), previewCard.heightAnchor.constraint(equalToConstant: 366)
        ])

        let eyebrow = label("MEET YOUR BUDDY", size: 9, weight: .bold, color: Palette.muted)
        setTracking(eyebrow, 1.0)
        previewCard.addSubview(eyebrow)
        let sparkle = symbol("sparkle", size: 12, color: selectedKind.color)
        previewCard.addSubview(sparkle)

        mascotPreview = MascotDrawingView(kind: selectedKind, frame: .zero)
        previewCard.addSubview(mascotPreview)
        previewName = label(selectedKind.mascotName, size: 19, weight: .bold, color: Palette.ink)
        previewType = label(selectedKind.title, size: 11, weight: .medium, color: Palette.ink.withAlphaComponent(0.68))
        previewCard.addSubview(previewName)
        previewCard.addSubview(previewType)

        for (index, kind) in ReminderKind.allCases.enumerated() {
            let button = button(kind.mascotName, size: 10, weight: .semibold, color: Palette.ink)
            button.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            button.target = self
            button.action = #selector(selectMascot(_:))
            button.wantsLayer = true
            button.layer?.cornerRadius = 8
            button.layer?.backgroundColor = kind.color.withAlphaComponent(kind == selectedKind ? 0.34 : 0.16).cgColor
            selectorButtons[kind] = button
            previewCard.addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14 + CGFloat(index) * 91),
                button.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 278),
                button.widthAnchor.constraint(equalToConstant: 82), button.heightAnchor.constraint(equalToConstant: 29)
            ])
        }

        let preview = button("▶   Preview reminder", size: 12, weight: .semibold, color: .white)
        preview.wantsLayer = true
        preview.layer?.backgroundColor = Palette.ink.cgColor
        preview.layer?.cornerRadius = 11
        preview.target = self
        preview.action = #selector(showPreview)
        previewCard.addSubview(preview)

        NSLayoutConstraint.activate([
            eyebrow.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16), eyebrow.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 16),
            sparkle.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -18), sparkle.centerYAnchor.constraint(equalTo: eyebrow.centerYAnchor),
            mascotPreview.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor), mascotPreview.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 44),
            mascotPreview.widthAnchor.constraint(equalToConstant: 148), mascotPreview.heightAnchor.constraint(equalToConstant: 148),
            previewName.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 17), previewName.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 203),
            previewType.leadingAnchor.constraint(equalTo: previewName.leadingAnchor), previewType.topAnchor.constraint(equalTo: previewName.bottomAnchor, constant: 4),
            preview.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14), preview.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            preview.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 320), preview.heightAnchor.constraint(equalToConstant: 34)
        ])

        let schedule = NSView()
        styleCard(schedule, radius: 18)
        addSubview(schedule)
        NSLayoutConstraint.activate([
            schedule.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30), schedule.topAnchor.constraint(equalTo: topAnchor, constant: 463),
            schedule.widthAnchor.constraint(equalToConstant: 300), schedule.heightAnchor.constraint(equalToConstant: 139)
        ])
        let scheduleTitle = label("DAILY RHYTHM", size: 9, weight: .bold, color: Palette.muted)
        setTracking(scheduleTitle, 1.0)
        let clock = symbol("clock.fill", size: 12, color: Palette.coral)
        schedule.addSubview(clock); schedule.addSubview(scheduleTitle)
        let workoutTitle = label("Workout window", size: 12, weight: .semibold, color: Palette.ink)
        let workoutInterval = label("Every \(scheduler.value(for: .workout).minutes) min", size: 10, weight: .regular, color: Palette.muted)
        let hours = label("2–6 PM", size: 10, weight: .bold, color: Palette.ink)
        hours.alignment = .center
        hours.wantsLayer = true
        hours.layer?.backgroundColor = Palette.coral.withAlphaComponent(0.18).cgColor
        hours.layer?.cornerRadius = 10
        let divider = NSView(); divider.wantsLayer = true; divider.layer?.backgroundColor = Palette.line.cgColor
        let info = symbol("info.circle", size: 10, color: Palette.muted)
        let note = label("Reminders run while Pippy stays open.", size: 9, weight: .medium, color: Palette.muted)
        for view in [workoutTitle, workoutInterval, hours, divider, info, note] { schedule.addSubview(view) }
        NSLayoutConstraint.activate([
            clock.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 16), clock.topAnchor.constraint(equalTo: schedule.topAnchor, constant: 16),
            scheduleTitle.leadingAnchor.constraint(equalTo: clock.trailingAnchor, constant: 7), scheduleTitle.centerYAnchor.constraint(equalTo: clock.centerYAnchor),
            workoutTitle.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 16), workoutTitle.topAnchor.constraint(equalTo: schedule.topAnchor, constant: 48),
            workoutInterval.leadingAnchor.constraint(equalTo: workoutTitle.leadingAnchor), workoutInterval.topAnchor.constraint(equalTo: workoutTitle.bottomAnchor, constant: 3),
            hours.trailingAnchor.constraint(equalTo: schedule.trailingAnchor, constant: -15), hours.centerYAnchor.constraint(equalTo: workoutTitle.centerYAnchor), hours.widthAnchor.constraint(equalToConstant: 59), hours.heightAnchor.constraint(equalToConstant: 23),
            divider.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 15), divider.trailingAnchor.constraint(equalTo: schedule.trailingAnchor, constant: -15), divider.topAnchor.constraint(equalTo: schedule.topAnchor, constant: 91), divider.heightAnchor.constraint(equalToConstant: 1),
            info.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 16), info.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 13),
            note.leadingAnchor.constraint(equalTo: info.trailingAnchor, constant: 6), note.centerYAnchor.constraint(equalTo: info.centerYAnchor)
        ])
    }

    private func buildFooter() {
        let footer = NSView()
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.55).cgColor
        addSubview(footer)
        let moon = symbol("moon.zzz.fill", size: 10, color: Palette.muted)
        let note = label("Your buddies nudge gently, then leave you to it.", size: 10, weight: .medium, color: Palette.muted)
        let badge = label("MENU BAR", size: 9, weight: .bold, color: Palette.muted)
        setTracking(badge, 1.0)
        for view in [moon, note, badge] { footer.addSubview(view) }
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: leadingAnchor), footer.trailingAnchor.constraint(equalTo: trailingAnchor), footer.bottomAnchor.constraint(equalTo: bottomAnchor), footer.heightAnchor.constraint(equalToConstant: 39),
            moon.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 30), moon.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            note.leadingAnchor.constraint(equalTo: moon.trailingAnchor, constant: 7), note.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            badge.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -30), badge.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
        ])
    }

    @objc private func selectMascot(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw) else { return }
        selectedKind = kind
        mascotPreview.kind = kind
        previewName.stringValue = kind.mascotName
        previewType.stringValue = kind.title
        for (item, button) in selectorButtons {
            button.layer?.backgroundColor = item.color.withAlphaComponent(item == kind ? 0.34 : 0.16).cgColor
        }
    }

    @objc private func showPreview() { scheduler.preview(selectedKind) }
}

final class PreferencesView: NSView {
    private let scheduler: ReminderScheduler
    private var soundCardView: NSView!
    private var soundToggleButton: NSButton!

    init(scheduler: ReminderScheduler, frame: NSRect) {
        self.scheduler = scheduler
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = Palette.canvas.cgColor
        buildContents()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        guard soundCardView != nil, soundToggleButton != nil else { return }
        soundToggleButton.frame = NSRect(
            x: soundCardView.bounds.width - 55,
            y: (soundCardView.bounds.height - 20) / 2,
            width: 40,
            height: 20
        )
    }

    private func buildContents() {
        let pawTile = NSView()
        pawTile.translatesAutoresizingMaskIntoConstraints = false
        pawTile.wantsLayer = true
        pawTile.layer?.backgroundColor = Palette.ink.cgColor
        pawTile.layer?.cornerRadius = 11
        let paw = symbol("pawprint.fill", size: 16, color: .white)
        pawTile.addSubview(paw)

        let title = label("A little care, on your terms.", size: 22, weight: .bold, color: Palette.ink)
        let subtitle = label("Choose which Pippy reminders pop up and when.", size: 11, weight: .regular, color: Palette.muted)
        let reminderHeading = label("REMINDERS", size: 9, weight: .bold, color: Palette.muted)
        setTracking(reminderHeading, 1.1)
        addSubview(pawTile); addSubview(title); addSubview(subtitle); addSubview(reminderHeading)
        NSLayoutConstraint.activate([
            pawTile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), pawTile.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            pawTile.widthAnchor.constraint(equalToConstant: 38), pawTile.heightAnchor.constraint(equalToConstant: 38),
            paw.centerXAnchor.constraint(equalTo: pawTile.centerXAnchor), paw.centerYAnchor.constraint(equalTo: pawTile.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: pawTile.trailingAnchor, constant: 13), title.topAnchor.constraint(equalTo: pawTile.topAnchor, constant: 1),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor), subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            reminderHeading.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32), reminderHeading.topAnchor.constraint(equalTo: topAnchor, constant: 94)
        ])

        let rows = NSStackView()
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.distribution = .fillEqually
        rows.spacing = 9
        rows.translatesAutoresizingMaskIntoConstraints = false
        for kind in ReminderKind.allCases {
            let row = ReminderRowView(kind: kind, scheduler: scheduler)
            row.widthAnchor.constraint(equalToConstant: 500).isActive = true
            row.heightAnchor.constraint(equalToConstant: 102).isActive = true
            rows.addArrangedSubview(row)
        }
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            rows.topAnchor.constraint(equalTo: topAnchor, constant: 116),
            rows.widthAnchor.constraint(equalToConstant: 500)
        ])

        let soundCard = NSView()
        soundCardView = soundCard
        styleCard(soundCard, radius: 15)
        addSubview(soundCard)
        let soundTitle = label("Gentle reminder and eye-break chimes", size: 12, weight: .semibold, color: Palette.ink)
        let soundDetail = label("Blink chimes at 20 seconds, 10 seconds, and completion.", size: 10, weight: .regular, color: Palette.muted)
        let soundToggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleSound(_:)))
        soundToggleButton = soundToggle
        soundToggle.translatesAutoresizingMaskIntoConstraints = true
        soundToggle.setButtonType(.switch)
        soundToggle.state = scheduler.soundEnabled ? .on : .off
        soundToggle.controlSize = .small
        soundCard.addSubview(soundTitle); soundCard.addSubview(soundDetail); soundCard.addSubview(soundToggle)
        NSLayoutConstraint.activate([
            soundCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), soundCard.topAnchor.constraint(equalTo: rows.bottomAnchor, constant: 16),
            soundCard.widthAnchor.constraint(equalToConstant: 500), soundCard.heightAnchor.constraint(equalToConstant: 64),
            soundTitle.leadingAnchor.constraint(equalTo: soundCard.leadingAnchor, constant: 15), soundTitle.topAnchor.constraint(equalTo: soundCard.topAnchor, constant: 13),
            soundDetail.leadingAnchor.constraint(equalTo: soundTitle.leadingAnchor), soundDetail.topAnchor.constraint(equalTo: soundTitle.bottomAnchor, constant: 3)
        ])

        let note = label("Workout nudges are limited to 2–6 p.m.  ·  Changes save automatically", size: 9, weight: .medium, color: Palette.muted)
        addSubview(note)
        NSLayoutConstraint.activate([
            note.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 31), note.topAnchor.constraint(equalTo: soundCard.bottomAnchor, constant: 13)
        ])
        needsLayout = true
    }

    @objc private func toggleSound(_ sender: NSButton) {
        scheduler.setSoundEnabled(sender.state == .on)
    }
}

final class ReminderRowView: NSView {
    private let kind: ReminderKind
    private let scheduler: ReminderScheduler
    private let intervalLabel: NSTextField
    private let stepper: NSStepper
    private let toggle: NSButton
    private var mascotTile: NSView!
    private var mascot: MascotDrawingView!
    private var name: NSTextField!
    private var category: NSTextField!
    private var tagline: NSTextField!

    override var isFlipped: Bool { true }

    init(kind: ReminderKind, scheduler: ReminderScheduler) {
        self.kind = kind
        self.scheduler = scheduler
        intervalLabel = label("Every \(scheduler.value(for: kind).minutes) min", size: 10, weight: .medium, color: Palette.muted)
        stepper = NSStepper()
        toggle = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.cornerRadius = 17
        layer?.borderWidth = 1
        layer?.borderColor = Palette.line.cgColor

        mascotTile = NSView(frame: .zero)
        mascotTile.translatesAutoresizingMaskIntoConstraints = true
        mascotTile.wantsLayer = true
        mascotTile.layer?.backgroundColor = kind.color.withAlphaComponent(0.22).cgColor
        mascotTile.layer?.cornerRadius = 15
        mascot = MascotDrawingView(kind: kind, frame: .zero)
        mascot.translatesAutoresizingMaskIntoConstraints = true
        mascotTile.addSubview(mascot)
        addSubview(mascotTile)

        name = label(kind.mascotName, size: 15, weight: .bold, color: Palette.ink)
        category = label(kind.title.uppercased(), size: 8, weight: .bold, color: Palette.muted)
        setTracking(category, 0.6)
        tagline = label(kind.tagline, size: 10, weight: .regular, color: Palette.muted)
        name.translatesAutoresizingMaskIntoConstraints = true
        category.translatesAutoresizingMaskIntoConstraints = true
        tagline.translatesAutoresizingMaskIntoConstraints = true
        intervalLabel.translatesAutoresizingMaskIntoConstraints = true
        addSubview(name); addSubview(category); addSubview(tagline); addSubview(intervalLabel)

        stepper.minValue = Double(kind.range.lowerBound)
        stepper.maxValue = Double(kind.range.upperBound)
        stepper.increment = Double(kind.step)
        stepper.integerValue = scheduler.value(for: kind).minutes
        stepper.target = self
        stepper.action = #selector(changeInterval(_:))
        stepper.controlSize = .small
        stepper.translatesAutoresizingMaskIntoConstraints = true
        addSubview(stepper)

        toggle.setButtonType(.switch)
        toggle.state = scheduler.value(for: kind).enabled ? .on : .off
        toggle.target = self
        toggle.action = #selector(toggleReminder(_:))
        toggle.title = ""
        toggle.controlSize = .small
        toggle.toolTip = "Enable or disable \(kind.title) reminders"
        toggle.translatesAutoresizingMaskIntoConstraints = true
        addSubview(toggle)
        needsLayout = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        mascotTile.frame = NSRect(x: 12, y: max(0, (bounds.height - 62) / 2), width: 62, height: 62)
        mascot.frame = NSRect(x: 2, y: 2, width: 58, height: 58)

        name.sizeToFit()
        name.frame.origin = NSPoint(x: 87, y: 14)
        category.sizeToFit()
        category.frame.origin = NSPoint(x: name.frame.maxX + 8, y: 18)
        tagline.sizeToFit()
        tagline.frame.origin = NSPoint(x: 87, y: 40)
        intervalLabel.sizeToFit()
        intervalLabel.frame.origin = NSPoint(x: 87, y: 67)
        stepper.frame = NSRect(x: intervalLabel.frame.maxX + 6, y: 63, width: 19, height: 27)
        toggle.frame = NSRect(x: bounds.width - 14 - 40, y: (bounds.height - 20) / 2, width: 40, height: 20)
    }

    @objc private func changeInterval(_ sender: NSStepper) {
        scheduler.setMinutes(sender.integerValue, for: kind)
        intervalLabel.stringValue = "Every \(sender.integerValue) min"
    }

    @objc private func toggleReminder(_ sender: NSButton) {
        scheduler.setEnabled(sender.state == .on, for: kind)
    }
}
