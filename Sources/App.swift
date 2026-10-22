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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
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
        window.makeKeyAndOrderFront(nil)
        self.window = window
        buildStatusMenu()
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
        menu.addItem(.separator())
        for kind in ReminderKind.allCases {
            let entry = NSMenuItem(title: "Preview \(kind.mascotName)", action: #selector(preview(_:)), keyEquivalent: "")
            entry.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
            menu.addItem(entry)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pippy", action: #selector(quitPippy), keyEquivalent: "q"))
        for menuItem in menu.items { menuItem.target = self }
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
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 590),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Pippy Preferences"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.backgroundColor = Palette.canvas
            window.contentView = PreferencesView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 560, height: 590))
            window.center()
            preferencesWindow = window
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func preview(_ sender: NSMenuItem) {
        guard let raw = sender.identifier?.rawValue, let kind = ReminderKind(rawValue: raw) else { return }
        scheduler?.preview(kind)
    }

    @objc private func quitPippy() { NSApp.terminate(nil) }
}
