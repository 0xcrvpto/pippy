import AppKit

/// Ways for people to reach the developer with bugs, concerns, or ideas.
enum Feedback {
    static let email = "0xcrvpto@webuild3.xyz"
    static let telegram = URL(string: "https://t.me/i0xcrvpto")!

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    static func emailURL() -> URL {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let body = """
        What happened, or what would you like to see?


        —
        Pippy \(appVersion) · macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)
        """
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = email
        parts.queryItems = [URLQueryItem(name: "subject", value: "Pippy feedback"), URLQueryItem(name: "body", value: body)]
        return parts.url!
    }

    static func openEmail() {
        guard !NSWorkspace.shared.open(emailURL()) else { return }
        // No mail app is set up: hand over the address instead.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(email, forType: .string)
        let alert = NSAlert()
        alert.messageText = "Email address copied"
        alert.informativeText = "No mail app opened, so \(email) is on your clipboard. Paste it into any email app, or reach out on Telegram instead."
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Telegram")
        if alert.runModal() == .alertSecondButtonReturn { openTelegram() }
    }

    static func openTelegram() { NSWorkspace.shared.open(telegram) }

    /// The shared "Email / Telegram" menu used by the dashboard, preferences, and menu bar.
    static func menu() -> NSMenu {
        let menu = NSMenu(title: "Send Feedback")
        let mail = NSMenuItem(title: "Email the Developer…", action: #selector(FeedbackActions.email), keyEquivalent: "")
        mail.image = NSImage(systemSymbolName: "envelope", accessibilityDescription: nil)
        let chat = NSMenuItem(title: "Message on Telegram…", action: #selector(FeedbackActions.telegram), keyEquivalent: "")
        chat.image = NSImage(systemSymbolName: "paperplane", accessibilityDescription: nil)
        for item in [mail, chat] { item.target = FeedbackActions.shared; menu.addItem(item) }
        return menu
    }
}

final class FeedbackActions: NSObject {
    static let shared = FeedbackActions()
    @objc func email() { Feedback.openEmail() }
    @objc func telegram() { Feedback.openTelegram() }
}
