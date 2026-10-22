import AppKit
import QuartzCore

final class MascotPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class FloatingPanelManager {
    private var panel: MascotPanel?
    private var pending: [() -> Void] = []

    func show(_ kind: ReminderKind, snooze: @escaping () -> Void, soundEnabled: @escaping () -> Bool, playCue: @escaping (ReminderCue) -> Void) {
        if panel?.isVisible == true {
            pending.append { [weak self] in self?.show(kind, snooze: snooze, soundEnabled: soundEnabled, playCue: playCue) }
            return
        }
        panel?.close()
        let panel = MascotPanel(contentRect: NSRect(x: 0, y: 0, width: 366, height: 254), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        let dismiss = { [weak panel, weak self] in
            guard let panel else { return }
            let finish = { [weak self, weak panel] in
                panel?.orderOut(nil)
                if let self, !self.pending.isEmpty { self.pending.removeFirst()() }
            }
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion { finish(); return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.18
                panel.animator().alphaValue = 0
            }, completionHandler: finish)
        }
        let reminder = CompanionReminderView(kind: kind, dismiss: dismiss, snooze: snooze, soundEnabled: soundEnabled(), playCue: playCue)
        panel.setContentSize(reminder.frame.size)
        panel.contentView = reminder
        if let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: visible.maxX - panel.frame.width - 20, y: visible.minY + 24))
        }
        self.panel = panel
        panel.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 1 : 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }
    }
}
