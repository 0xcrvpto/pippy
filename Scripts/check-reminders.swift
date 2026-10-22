import AppKit
@main struct Check {
 static func main() {
  _ = NSApplication.shared
  var snoozes = 0; var dismissals = 0; var completed = 0; var cues: [Bool] = []
  for kind in ReminderKind.allCases {
   let view = CompanionReminderView(kind: kind, dismiss: { dismissals += 1 }, snooze: { snoozes += 1 }, playCue: {_ in})
   let later = view.subviews.compactMap { $0 as? NSButton }.first { $0.title == "In 10 minutes" }!
   later.performClick(nil)
  }
  precondition(snoozes == 3 && dismissals == 3)
  let eye = CompanionReminderView(kind: .eyes, dismiss: {}, snooze: {}, playCue: { cues.append($0); if $0 { completed += 1 } })
  let start = eye.subviews.compactMap { $0 as? NSButton }.first { $0.title == "Start break" }!
  start.performClick(nil)
  precondition(start.title == "Resting…" && !start.isEnabled)
  precondition(cues == [false])
  RunLoop.current.run(until: Date().addingTimeInterval(10.6))
  precondition(cues == [false, false])
  RunLoop.current.run(until: Date().addingTimeInterval(10.0))
  precondition(start.title == "Done" && start.isEnabled && completed == 1)
  precondition(cues == [false, false, true])
  print("PASS: three cues at 20, 10 and 0 seconds; all three snooze actions; eye break starts, completes, and emits one completion cue")
 }
}
