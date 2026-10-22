import AppKit
import QuartzCore

final class DashboardView: NSView {
    private let scheduler: ReminderScheduler
    private var selectedKind: ReminderKind = .stretch
    private var previewCard: NSView!
    private var mascotPreview: MascotDrawingView!
    private var previewName: NSTextField!
    private var previewType: NSTextField!
    private var rhythmTags: [ReminderKind: TagView] = [:]
    private var rhythmDetails: [ReminderKind: NSTextField] = [:]
    private var statusDot: NSView!
    private var statusLabel: NSTextField!
    private var selectorButtons: [ReminderKind: PillButton] = [:]
    private var feedbackBanner: FeedbackBanner!
    private(set) var updateBanner: UpdateBanner!

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
        refreshSchedule()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSchedule), name: .pippySettingsChanged, object: scheduler)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvailable(_:)), name: .pippyUpdateAvailable, object: nil)
        if let release = (NSApp.delegate as? AppDelegate)?.updates?.available { showUpdate(release) }
    }

    /// Swaps the feedback card for an update banner; feedback stays in the header.
    func showUpdate(_ release: ReleaseInfo) {
        updateBanner.release = release
        updateBanner.isHidden = false
        feedbackBanner.isHidden = true
    }

    @objc private func updateAvailable(_ note: Notification) {
        guard let release = note.userInfo?["release"] as? ReleaseInfo else { return }
        showUpdate(release)
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
        status.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.85).cgColor
        status.layer?.cornerRadius = 13
        statusDot = NSView()
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 3.5
        status.addSubview(statusDot)
        statusLabel = label("", size: 9, weight: .bold, color: Palette.ink.withAlphaComponent(0.72))
        status.addSubview(statusLabel)
        addSubview(status)

        let preferences = softPill("Preferences", symbol: "gearshape.fill")
        preferences.target = NSApp.delegate
        preferences.action = #selector(AppDelegate.openPreferences)
        addSubview(preferences)
        let feedback = softPill("Feedback", symbol: "bubble.left.fill")
        feedback.target = self
        feedback.action = #selector(showFeedbackMenu(_:))
        feedback.toolTip = "Report a problem or share an idea"
        addSubview(feedback)
        NSLayoutConstraint.activate([
            iconTile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), iconTile.topAnchor.constraint(equalTo: topAnchor, constant: 23),
            pip.leadingAnchor.constraint(equalTo: iconTile.trailingAnchor, constant: 9), pip.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            subtitle.leadingAnchor.constraint(equalTo: pip.trailingAnchor, constant: 12), subtitle.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            status.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30), status.centerYAnchor.constraint(equalTo: iconTile.centerYAnchor),
            status.heightAnchor.constraint(equalToConstant: 27),
            statusDot.leadingAnchor.constraint(equalTo: status.leadingAnchor, constant: 11), statusDot.centerYAnchor.constraint(equalTo: status.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 7), statusDot.heightAnchor.constraint(equalToConstant: 7),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 7), statusLabel.centerYAnchor.constraint(equalTo: status.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: status.trailingAnchor, constant: -12),
            preferences.trailingAnchor.constraint(equalTo: status.leadingAnchor, constant: -8), preferences.centerYAnchor.constraint(equalTo: status.centerYAnchor),
            preferences.heightAnchor.constraint(equalToConstant: 27),
            feedback.trailingAnchor.constraint(equalTo: preferences.leadingAnchor, constant: -8), feedback.centerYAnchor.constraint(equalTo: status.centerYAnchor),
            feedback.heightAnchor.constraint(equalToConstant: 27)
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

        feedbackBanner = FeedbackBanner()
        updateBanner = UpdateBanner()
        updateBanner.isHidden = true
        updateBanner.onDismiss = { [weak self] in self?.updateBanner.isHidden = true; self?.feedbackBanner.isHidden = false }
        for banner in [feedbackBanner!, updateBanner!] as [NSView] {
            addSubview(banner)
            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: rows.leadingAnchor), banner.topAnchor.constraint(equalTo: rows.bottomAnchor, constant: 14),
                banner.widthAnchor.constraint(equalToConstant: 570), banner.heightAnchor.constraint(equalToConstant: 54)
            ])
        }
    }

    private func buildRightColumn() {
        previewCard = NSView()
        styleCard(previewCard, radius: 22)
        addSubview(previewCard)
        NSLayoutConstraint.activate([
            previewCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
            previewCard.topAnchor.constraint(equalTo: topAnchor, constant: 82),
            previewCard.widthAnchor.constraint(equalToConstant: 300), previewCard.heightAnchor.constraint(equalToConstant: 348)
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
            let button = PillButton(title: kind.mascotName, size: 10, weight: .semibold, color: Palette.ink,
                                    fill: kind.color.withAlphaComponent(0.16), hoverFill: kind.color.withAlphaComponent(0.28), radius: 8)
            button.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            button.target = self
            button.action = #selector(selectMascot(_:))
            selectorButtons[kind] = button
            previewCard.addSubview(button)
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14 + CGFloat(index) * 91),
                button.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 260),
                button.widthAnchor.constraint(equalToConstant: 82), button.heightAnchor.constraint(equalToConstant: 29)
            ])
        }
        highlightSelector()

        let preview = inkPill("Preview reminder", symbol: "play.fill")
        preview.target = self
        preview.action = #selector(showPreview)
        previewCard.addSubview(preview)

        NSLayoutConstraint.activate([
            eyebrow.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 16), eyebrow.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 16),
            sparkle.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -18), sparkle.centerYAnchor.constraint(equalTo: eyebrow.centerYAnchor),
            mascotPreview.centerXAnchor.constraint(equalTo: previewCard.centerXAnchor), mascotPreview.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 40),
            mascotPreview.widthAnchor.constraint(equalToConstant: 144), mascotPreview.heightAnchor.constraint(equalToConstant: 144),
            previewName.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 17), previewName.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 194),
            previewType.leadingAnchor.constraint(equalTo: previewName.leadingAnchor), previewType.topAnchor.constraint(equalTo: previewName.bottomAnchor, constant: 4),
            preview.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14), preview.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            preview.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 300), preview.heightAnchor.constraint(equalToConstant: 34)
        ])

        let schedule = NSView()
        styleCard(schedule, radius: 18)
        addSubview(schedule)
        NSLayoutConstraint.activate([
            schedule.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30), schedule.topAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: 14),
            schedule.widthAnchor.constraint(equalToConstant: 300), schedule.heightAnchor.constraint(equalToConstant: 162)
        ])
        let scheduleTitle = label("DAILY RHYTHM", size: 9, weight: .bold, color: Palette.muted)
        setTracking(scheduleTitle, 1.0)
        let clock = symbol("clock.fill", size: 12, color: Palette.coral)
        schedule.addSubview(clock); schedule.addSubview(scheduleTitle)

        // One row per buddy: what it does, how often, and its active hours.
        var previous: NSView?
        for kind in ReminderKind.allCases {
            let title = label(kind == .workout ? "Workout" : kind == .eyes ? "Eye breaks" : "Stretch", size: 12, weight: .semibold, color: Palette.ink)
            let detail = label("", size: 10, weight: .regular, color: Palette.muted)
            let tag = TagView(scheduler.activeHours(for: kind).summary, tint: kind.color)
            rhythmDetails[kind] = detail
            rhythmTags[kind] = tag
            for view in [title, detail, tag] { schedule.addSubview(view) }
            NSLayoutConstraint.activate([
                title.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 16),
                title.topAnchor.constraint(equalTo: previous?.bottomAnchor ?? schedule.topAnchor, constant: previous == nil ? 40 : 9),
                detail.leadingAnchor.constraint(equalTo: title.leadingAnchor), detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 1),
                tag.trailingAnchor.constraint(equalTo: schedule.trailingAnchor, constant: -15), tag.centerYAnchor.constraint(equalTo: title.bottomAnchor)
            ])
            previous = detail
        }
        NSLayoutConstraint.activate([
            clock.leadingAnchor.constraint(equalTo: schedule.leadingAnchor, constant: 16), clock.topAnchor.constraint(equalTo: schedule.topAnchor, constant: 16),
            scheduleTitle.leadingAnchor.constraint(equalTo: clock.trailingAnchor, constant: 7), scheduleTitle.centerYAnchor.constraint(equalTo: clock.centerYAnchor)
        ])
    }

    private func buildFooter() {
        let footer = NSView()
        footer.translatesAutoresizingMaskIntoConstraints = false
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.55).cgColor
        addSubview(footer)
        let moon = symbol("moon.zzz.fill", size: 10, color: Palette.muted)
        let note = label("Your buddies nudge gently, then leave you to it.", size: 10, weight: .medium, color: Palette.muted)
        let badge = label("PIPPY \(Feedback.appVersion.uppercased())", size: 9, weight: .bold, color: Palette.muted)
        setTracking(badge, 1.0)
        for view in [moon, note, badge] { footer.addSubview(view) }
        NSLayoutConstraint.activate([
            footer.leadingAnchor.constraint(equalTo: leadingAnchor), footer.trailingAnchor.constraint(equalTo: trailingAnchor), footer.bottomAnchor.constraint(equalTo: bottomAnchor), footer.heightAnchor.constraint(equalToConstant: 39),
            moon.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 30), moon.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            note.leadingAnchor.constraint(equalTo: moon.trailingAnchor, constant: 7), note.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            badge.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -30), badge.centerYAnchor.constraint(equalTo: footer.centerYAnchor)
        ])
    }

    private func highlightSelector() {
        for (kind, button) in selectorButtons {
            button.layer?.borderWidth = kind == selectedKind ? 1.5 : 0
            button.layer?.borderColor = kind.color.withAlphaComponent(0.85).cgColor
        }
    }

    @objc private func selectMascot(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw) else { return }
        selectedKind = kind
        mascotPreview.kind = kind
        previewName.stringValue = kind.mascotName
        previewType.stringValue = kind.title
        highlightSelector()
    }

    @objc private func showFeedbackMenu(_ sender: NSButton) {
        Feedback.menu().popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    @objc private func refreshSchedule() {
        for kind in ReminderKind.allCases {
            let settings = scheduler.value(for: kind)
            rhythmTags[kind]?.text.stringValue = scheduler.activeHours(for: kind).summary
            rhythmDetails[kind]?.stringValue = settings.enabled ? "\(kind.mascotName), every \(settings.minutes) min" : "\(kind.mascotName), paused"
        }
        let count = scheduler.enabledCount
        statusDot.layer?.backgroundColor = (count > 0 ? Palette.green : Palette.muted).cgColor
        statusLabel.stringValue = count == 0 ? "ALL PAUSED" : count == 1 ? "1 REMINDER ON" : "\(count) REMINDERS ON"
        setTracking(statusLabel, 0.7)
    }

    @objc private func showPreview() { scheduler.preview(selectedKind) }
}

/// "Something off, or have an idea?" with direct Email and Telegram buttons.
final class FeedbackBanner: NSView {
    init() {
        super.init(frame: .zero)
        styleCard(self, radius: 16)
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.7).cgColor
        let icon = symbol("bubble.left.and.bubble.right.fill", size: 14, color: Palette.lilac)
        let title = label("Something off, or have an idea?", size: 12, weight: .semibold, color: Palette.ink)
        let detail = label("Tell me directly — every message gets read.", size: 10, weight: .regular, color: Palette.muted)
        let email = PillButton(title: "Email", symbol: "envelope.fill", size: 10, weight: .semibold, color: Palette.ink,
                               fill: Palette.lilac.withAlphaComponent(0.18), hoverFill: Palette.lilac.withAlphaComponent(0.32))
        email.target = FeedbackActions.shared; email.action = #selector(FeedbackActions.email)
        email.toolTip = Feedback.email
        let telegram = PillButton(title: "Telegram", symbol: "paperplane.fill", size: 10, weight: .semibold, color: Palette.ink,
                                  fill: Palette.mint.withAlphaComponent(0.2), hoverFill: Palette.mint.withAlphaComponent(0.36))
        telegram.target = FeedbackActions.shared; telegram.action = #selector(FeedbackActions.telegram)
        telegram.toolTip = Feedback.telegram.absoluteString
        for view in [icon, title, detail, email, telegram] { addSubview(view) }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16), icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 11), title.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor), detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            telegram.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14), telegram.centerYAnchor.constraint(equalTo: centerYAnchor),
            telegram.heightAnchor.constraint(equalToConstant: 28),
            email.trailingAnchor.constraint(equalTo: telegram.leadingAnchor, constant: -8), email.centerYAnchor.constraint(equalTo: centerYAnchor),
            email.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// "Pippy 0.7 is ready" with What's new and Download buttons.
final class UpdateBanner: NSView {
    var release: ReleaseInfo? { didSet { title.stringValue = "Pippy \(release?.version ?? "") is ready" } }
    var onDismiss: () -> Void = {}
    private let title = label("", size: 12, weight: .semibold, color: Palette.ink)

    init() {
        super.init(frame: .zero)
        styleCard(self, radius: 16)
        layer?.backgroundColor = Palette.green.withAlphaComponent(0.1).cgColor
        layer?.borderColor = Palette.green.withAlphaComponent(0.4).cgColor
        let icon = symbol("arrow.down.circle.fill", size: 20, color: Palette.green)
        icon.imageScaling = .scaleProportionallyUpOrDown
        let detail = label("Download it and drag it into Applications.", size: 10, weight: .regular, color: Palette.muted)
        let notes = PillButton(title: "What's new", size: 10, weight: .semibold, color: Palette.ink,
                               fill: NSColor.white.withAlphaComponent(0.8), hoverFill: .white)
        notes.target = self; notes.action = #selector(openNotes)
        let download = inkPill("Download", symbol: "arrow.down", size: 10, radius: 14)
        download.target = self; download.action = #selector(openDownload)
        let close = symbolButton("xmark", color: Palette.muted)
        close.target = self; close.action = #selector(dismiss); close.toolTip = "Hide until next launch"
        close.setAccessibilityLabel("Hide update banner")
        for button in [notes, download] { button.setContentCompressionResistancePriority(.required, for: .horizontal) }
        for view in [icon, title, detail, notes, download, close] { addSubview(view) }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16), icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20), icon.heightAnchor.constraint(equalToConstant: 20),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 11), title.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor), detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 2),
            detail.trailingAnchor.constraint(lessThanOrEqualTo: notes.leadingAnchor, constant: -10),
            close.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10), close.centerYAnchor.constraint(equalTo: centerYAnchor),
            close.widthAnchor.constraint(equalToConstant: 18), close.heightAnchor.constraint(equalToConstant: 18),
            download.trailingAnchor.constraint(equalTo: close.leadingAnchor, constant: -8), download.centerYAnchor.constraint(equalTo: centerYAnchor),
            download.heightAnchor.constraint(equalToConstant: 28),
            notes.trailingAnchor.constraint(equalTo: download.leadingAnchor, constant: -8), notes.centerYAnchor.constraint(equalTo: centerYAnchor),
            notes.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func openNotes() { if let release { NSWorkspace.shared.open(release.page) } }
    @objc private func openDownload() { if let release { NSWorkspace.shared.open(release.download) } }
    @objc private func dismiss() { onDismiss() }
}

final class PreferencesView: NSView {
    private let scheduler: ReminderScheduler
    private(set) var soundToggle: NSSwitch!
    private(set) var soundPickers: [ReminderKind: NSPopUpButton] = [:]

    init(scheduler: ReminderScheduler, frame: NSRect) {
        self.scheduler = scheduler
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        wantsLayer = true
        layer?.backgroundColor = Palette.canvas.cgColor
        buildContents()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildContents() {
        let pawTile = NSView()
        pawTile.translatesAutoresizingMaskIntoConstraints = false
        pawTile.wantsLayer = true
        pawTile.layer?.backgroundColor = Palette.ink.cgColor
        pawTile.layer?.cornerRadius = 11
        let paw = symbol("pawprint.fill", size: 16, color: .white)
        pawTile.addSubview(paw)

        let title = label("A little care, on your terms.", size: 22, weight: .bold, color: Palette.ink)
        let subtitle = label("Choose which Pippy reminders pop up, when, and how they sound.", size: 11, weight: .regular, color: Palette.muted)
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
        rows.spacing = 8
        rows.translatesAutoresizingMaskIntoConstraints = false
        for kind in ReminderKind.allCases {
            let row = ReminderRowView(kind: kind, scheduler: scheduler)
            row.widthAnchor.constraint(equalToConstant: 500).isActive = true
            row.heightAnchor.constraint(equalToConstant: 84).isActive = true
            rows.addArrangedSubview(row)
        }
        addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            rows.topAnchor.constraint(equalTo: topAnchor, constant: 114),
            rows.widthAnchor.constraint(equalToConstant: 500)
        ])

        let workoutHours = ActiveHoursView(scheduler: scheduler)
        addSubview(workoutHours)
        NSLayoutConstraint.activate([
            workoutHours.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30),
            workoutHours.topAnchor.constraint(equalTo: rows.bottomAnchor, constant: 12),
            workoutHours.widthAnchor.constraint(equalToConstant: 500), workoutHours.heightAnchor.constraint(equalToConstant: 160)
        ])

        let soundCard = buildSoundCard()
        addSubview(soundCard)
        NSLayoutConstraint.activate([
            soundCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30), soundCard.topAnchor.constraint(equalTo: workoutHours.bottomAnchor, constant: 12),
            soundCard.widthAnchor.constraint(equalToConstant: 500)
        ])

        let note = label("Changes save automatically · sound previews play even when muted", size: 9, weight: .medium, color: Palette.muted)
        let ask = label("Feedback?", size: 9, weight: .semibold, color: Palette.muted)
        let email = button("Email", size: 9, weight: .bold, color: Palette.ink)
        email.target = FeedbackActions.shared; email.action = #selector(FeedbackActions.email); email.toolTip = Feedback.email
        let dot = label("·", size: 9, weight: .bold, color: Palette.muted)
        let telegram = button("Telegram", size: 9, weight: .bold, color: Palette.ink)
        telegram.target = FeedbackActions.shared; telegram.action = #selector(FeedbackActions.telegram); telegram.toolTip = Feedback.telegram.absoluteString
        for view in [note, ask, email, dot, telegram] { addSubview(view) }
        NSLayoutConstraint.activate([
            note.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 31), note.topAnchor.constraint(equalTo: soundCard.bottomAnchor, constant: 13),
            telegram.trailingAnchor.constraint(equalTo: soundCard.trailingAnchor, constant: -1), telegram.centerYAnchor.constraint(equalTo: note.centerYAnchor),
            dot.trailingAnchor.constraint(equalTo: telegram.leadingAnchor, constant: -4), dot.centerYAnchor.constraint(equalTo: note.centerYAnchor),
            email.trailingAnchor.constraint(equalTo: dot.leadingAnchor, constant: -4), email.centerYAnchor.constraint(equalTo: note.centerYAnchor),
            ask.trailingAnchor.constraint(equalTo: email.leadingAnchor, constant: -5), ask.centerYAnchor.constraint(equalTo: note.centerYAnchor)
        ])
    }

    private func buildSoundCard() -> NSView {
        let card = NSView()
        styleCard(card, radius: 15)
        let title = label("Reminder sounds", size: 12, weight: .semibold, color: Palette.ink)
        let detail = label("Give each buddy its own sound. Blink chimes at 20 s, 10 s, and when done.", size: 10, weight: .regular, color: Palette.muted)
        soundToggle = NSSwitch()
        soundToggle.translatesAutoresizingMaskIntoConstraints = false
        soundToggle.controlSize = .small
        soundToggle.state = scheduler.soundEnabled ? .on : .off
        soundToggle.target = self
        soundToggle.action = #selector(toggleSound(_:))
        soundToggle.setAccessibilityLabel("Reminder sounds")
        for view in [title, detail, soundToggle!] { card.addSubview(view) }
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15), title.topAnchor.constraint(equalTo: card.topAnchor, constant: 13),
            detail.leadingAnchor.constraint(equalTo: title.leadingAnchor), detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
            soundToggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15), soundToggle.centerYAnchor.constraint(equalTo: title.centerYAnchor, constant: 6)
        ])

        var previous: NSView = detail
        for kind in ReminderKind.allCases {
            let row = NSView()
            row.translatesAutoresizingMaskIntoConstraints = false
            let mascot = MascotDrawingView(kind: kind, frame: .zero)
            let name = label(kind.mascotName, size: 11, weight: .semibold, color: Palette.ink)
            let use = label(kind == .eyes ? "Break chimes" : "Nudge sound", size: 10, weight: .regular, color: Palette.muted)
            let picker = NSPopUpButton(frame: .zero, pullsDown: false)
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.controlSize = .small
            picker.font = .systemFont(ofSize: 11)
            picker.addItems(withTitles: SoundSet.allCases.map(\.title))
            picker.selectItem(at: SoundSet.allCases.firstIndex(of: scheduler.soundSet(for: kind)) ?? 0)
            picker.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            picker.target = self
            picker.action = #selector(chooseSound(_:))
            picker.setAccessibilityLabel("\(kind.mascotName) sound")
            soundPickers[kind] = picker
            let play = PillButton(title: "Preview", symbol: "play.fill", size: 10, weight: .semibold, color: Palette.ink,
                                  fill: kind.color.withAlphaComponent(0.16), hoverFill: kind.color.withAlphaComponent(0.3))
            play.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            play.target = self
            play.action = #selector(previewSound(_:))
            play.setAccessibilityLabel("Preview \(kind.mascotName)'s sound")
            for view in [mascot, name, use, picker, play] { row.addSubview(view) }
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12), row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
                row.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: previous === detail ? 10 : 4), row.heightAnchor.constraint(equalToConstant: 30),
                mascot.leadingAnchor.constraint(equalTo: row.leadingAnchor), mascot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                mascot.widthAnchor.constraint(equalToConstant: 28), mascot.heightAnchor.constraint(equalToConstant: 28),
                name.leadingAnchor.constraint(equalTo: mascot.trailingAnchor, constant: 8), name.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                use.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 96), use.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                play.trailingAnchor.constraint(equalTo: row.trailingAnchor), play.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                play.heightAnchor.constraint(equalToConstant: 24), play.widthAnchor.constraint(equalToConstant: 86),
                picker.trailingAnchor.constraint(equalTo: play.leadingAnchor, constant: -10), picker.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                picker.widthAnchor.constraint(equalToConstant: 132)
            ])
            previous = row
        }
        card.bottomAnchor.constraint(equalTo: previous.bottomAnchor, constant: 10).isActive = true
        return card
    }

    @objc private func chooseSound(_ sender: NSPopUpButton) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw),
              SoundSet.allCases.indices.contains(sender.indexOfSelectedItem) else { return }
        scheduler.setSoundSet(SoundSet.allCases[sender.indexOfSelectedItem], for: kind)
        scheduler.previewSound(for: kind)
    }

    @objc private func previewSound(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw) else { return }
        scheduler.previewSound(for: kind)
    }

    @objc private func toggleSound(_ sender: NSSwitch) {
        scheduler.setSoundEnabled(sender.state == .on)
    }
}

final class ReminderRowView: NSView {
    private let kind: ReminderKind
    private let scheduler: ReminderScheduler
    private let every: NSTextField
    private(set) var intervalChip: ScrollPickerChip
    private(set) var toggle: NSSwitch
    private var mascotTile: NSView!
    private var mascot: MascotDrawingView!
    private var name: NSTextField!
    private var category: NSTextField!
    private var tagline: NSTextField!

    override var isFlipped: Bool { true }

    init(kind: ReminderKind, scheduler: ReminderScheduler) {
        self.kind = kind
        self.scheduler = scheduler
        every = label("Every", size: 10, weight: .medium, color: Palette.muted)
        intervalChip = ScrollPickerChip(values: Array(stride(from: kind.range.lowerBound, through: kind.range.upperBound, by: kind.step)),
                                        selected: scheduler.value(for: kind).minutes, wraps: false, tint: kind.color) { "\($0) min" }
        toggle = NSSwitch()
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
        for view in [name!, category!, tagline!, every] {
            view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(view)
        }

        intervalChip.translatesAutoresizingMaskIntoConstraints = true
        intervalChip.setAccessibilityLabel("\(kind.title) interval")
        intervalChip.toolTip = "Scroll, drag, or click to change"
        intervalChip.onChange = { [weak self] minutes in
            guard let self else { return }
            self.scheduler.setMinutes(minutes, for: self.kind)
        }
        addSubview(intervalChip)

        toggle.state = scheduler.value(for: kind).enabled ? .on : .off
        toggle.target = self
        toggle.action = #selector(toggleReminder(_:))
        toggle.controlSize = .small
        toggle.toolTip = "Turn \(kind.title.lowercased()) reminders on or off"
        toggle.setAccessibilityLabel("\(kind.title) reminders")
        toggle.translatesAutoresizingMaskIntoConstraints = true
        addSubview(toggle)
        applyEnabledLook()
        // The dashboard and preferences each show these rows; keep both in sync.
        NotificationCenter.default.addObserver(self, selector: #selector(syncFromSettings), name: .pippySettingsChanged, object: scheduler)
        needsLayout = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        let compact = bounds.height < 95
        let tileSize: CGFloat = compact ? 56 : 62
        mascotTile.frame = NSRect(x: 12, y: max(0, (bounds.height - tileSize) / 2), width: tileSize, height: tileSize)
        mascot.frame = mascotTile.bounds.insetBy(dx: 2, dy: 2)

        let textX = tileSize + 25
        name.sizeToFit()
        name.frame.origin = NSPoint(x: textX, y: compact ? 9 : 14)
        category.sizeToFit()
        category.frame.origin = NSPoint(x: name.frame.maxX + 8, y: name.frame.minY + 4)
        tagline.sizeToFit()
        tagline.frame.origin = NSPoint(x: textX, y: compact ? 31 : 38)
        let chipSize = intervalChip.intrinsicContentSize
        let chipY: CGFloat = compact ? 50 : 62
        every.sizeToFit()
        every.frame.origin = NSPoint(x: textX, y: chipY + (chipSize.height - every.frame.height) / 2)
        intervalChip.frame = NSRect(x: every.frame.maxX + 6, y: chipY, width: chipSize.width, height: chipSize.height)
        let switchSize = toggle.intrinsicContentSize
        toggle.frame = NSRect(x: bounds.width - 16 - switchSize.width, y: (bounds.height - switchSize.height) / 2, width: switchSize.width, height: switchSize.height)
    }

    private func applyEnabledLook() {
        let alpha: CGFloat = toggle.state == .on ? 1 : 0.45
        for view in [mascotTile!, name!, category!, tagline!, every, intervalChip] { view.alphaValue = alpha }
    }

    @objc private func syncFromSettings() {
        let settings = scheduler.value(for: kind)
        toggle.state = settings.enabled ? .on : .off
        if intervalChip.value != settings.minutes { intervalChip.select(settings.minutes) }
        applyEnabledLook()
    }

    @objc private func toggleReminder(_ sender: NSSwitch) {
        scheduler.setEnabled(sender.state == .on, for: kind)
        applyEnabledLook()
    }
}
