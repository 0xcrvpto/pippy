import AppKit
import QuartzCore

#if !PREVIEW_RENDERER
@main
struct PippyMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
#endif

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var scheduler: ReminderScheduler?
    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    private(set) var updates: UpdateChecker?
    private var updateMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // Pippy's palette is light-only; keep system controls (switches, menus) matching it in Dark Mode.
        NSApp.appearance = NSAppearance(named: .aqua)
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        let scheduler = ReminderScheduler()
        self.scheduler = scheduler

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pippy"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 920, height: 640)
        window.backgroundColor = Palette.canvas
        window.contentView = DashboardView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 960, height: 660))
        window.center()
        // Don't land keyboard focus on the first pill at launch; Tab still reaches every control.
        window.initialFirstResponder = window.contentView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(nil)
        self.window = window
        buildStatusMenu()
        let updates = UpdateChecker()
        self.updates = updates
        NotificationCenter.default.addObserver(self, selector: #selector(updateAvailable(_:)), name: .pippyUpdateAvailable, object: updates)
        updates.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func buildStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Pippy reminders")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Pippy", action: #selector(openPippy), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ","))
        let update = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
        updateMenuItem = update
        menu.addItem(update)
        menu.addItem(.separator())
        for kind in ReminderKind.allCases {
            let entry = NSMenuItem(title: "Preview \(kind.mascotName)", action: #selector(preview(_:)), keyEquivalent: "")
            entry.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            menu.addItem(entry)
        }
        menu.addItem(.separator())
        let feedback = NSMenuItem(title: "Send Feedback", action: nil, keyEquivalent: "")
        feedback.submenu = Feedback.menu()
        menu.addItem(feedback)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pippy", action: #selector(quitPippy), keyEquivalent: "q"))
        for menuItem in menu.items where menuItem.submenu == nil { menuItem.target = self }
        item.menu = menu
        statusItem = item
    }

    @objc private func openPippy() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openPreferences() {
        if let preferencesWindow {
            preferencesWindow.makeKeyAndOrderFront(nil)
        } else if let scheduler {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 716),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Pippy Preferences"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = Palette.canvas
            window.contentView = PreferencesView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 560, height: 716))
            window.center()
            preferencesWindow = window
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func preview(_ sender: NSMenuItem) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw) else { return }
        scheduler?.preview(kind)
    }

    @objc private func updateAvailable(_ note: Notification) {
        guard let release = note.userInfo?["release"] as? ReleaseInfo else { return }
        updateMenuItem?.title = "Download Pippy \(release.version)…"
    }

    @objc private func checkForUpdates() {
        if let release = updates?.available { NSWorkspace.shared.open(release.download); return }
        updates?.check { result in
            let alert = NSAlert()
            switch result {
            case .success(let release?):
                alert.messageText = "Pippy \(release.version) is available"
                alert.informativeText = "You have \(Feedback.appVersion). Download the new version, then drag it into Applications to replace this one."
                alert.addButton(withTitle: "Download")
                alert.addButton(withTitle: "Later")
                NSApp.activate(ignoringOtherApps: true)
                if alert.runModal() == .alertFirstButtonReturn { NSWorkspace.shared.open(release.download) }
                return
            case .success(nil):
                alert.messageText = "You're up to date"
                alert.informativeText = "Pippy \(Feedback.appVersion) is the latest version."
            case .failure:
                alert.messageText = "Couldn't check for updates"
                alert.informativeText = "Check your internet connection and try again, or visit github.com/0xcrvpto/pippy/releases."
            }
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    @objc private func quitPippy() { NSApp.terminate(nil) }
}
