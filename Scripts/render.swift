import AppKit
@main struct Render {
 static func main() {
  let app = NSApplication.shared
  app.setActivationPolicy(.prohibited)
  for kind in ReminderKind.allCases {
   let view = CompanionReminderView(kind: kind, dismiss: {}, snooze: {}, playCue: {_ in})
   let window = NSWindow(contentRect: view.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
   window.contentView = view
   view.layoutSubtreeIfNeeded()
   let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
   view.cacheDisplay(in: view.bounds, to: rep)
   try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Previews/\(kind.mascotName).png"))
  }
 }
}
