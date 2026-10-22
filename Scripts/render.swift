import AppKit
@main struct Render {
 static func main() {
  let app = NSApplication.shared
  app.setActivationPolicy(.prohibited)
  app.appearance = NSAppearance(named: .aqua)
  let suite = "PippyRender-" + UUID().uuidString
  let defaults = UserDefaults(suiteName: suite)!
  defer { defaults.removePersistentDomain(forName: suite) }
  let scheduler = ReminderScheduler(defaults: defaults, startTimer: false)
  var views: [(String, NSView)] = [
    ("Preferences", PreferencesView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 560, height: 716))),
    ("Dashboard", DashboardView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 960, height: 660)))
  ]
  for kind in ReminderKind.allCases {
    views.append((kind.mascotName, CompanionReminderView(kind: kind, dismiss: {}, snooze: {}, playCue: {_ in})))
  }
  for (name, view) in views {
   let window = NSWindow(contentRect: view.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
   window.contentView = view
   view.layoutSubtreeIfNeeded()
   guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { fatalError("Cannot render \(name) at \(view.bounds)") }
   view.cacheDisplay(in: view.bounds, to: rep)
   try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Previews/\(name).png"))
  }
 }
}
