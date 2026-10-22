import AppKit
@main struct Check {
 static func main() {
  _ = NSApplication.shared
  let suite = "PippyChecks-" + UUID().uuidString
  let defaults = UserDefaults(suiteName: suite)!
  defer { defaults.removePersistentDomain(forName: suite) }
  let scheduler = ReminderScheduler(defaults: defaults, startTimer: false)
  precondition(scheduler.workoutWindow == .standard)
  precondition(scheduler.setWorkoutWindow(start: 9*60+15, end: 11*60+45))
  let daytime = scheduler.workoutWindow
  precondition(!daytime.contains(minute: 554) && daytime.isSlot(minute: 555, interval: 60))
  precondition(daytime.isSlot(minute: 615, interval: 60) && !daytime.isSlot(minute: 616, interval: 60))
  precondition(!daytime.contains(minute: 705))
  let reloaded = ReminderScheduler(defaults: defaults, startTimer: false)
  precondition(reloaded.workoutWindow == daytime)
  precondition(!scheduler.setWorkoutWindow(start: 100, end: 100))
  precondition(!scheduler.setWorkoutWindow(start: -1, end: 100))
  precondition(scheduler.workoutWindow == daytime)
  precondition(scheduler.setWorkoutWindow(start: 22*60+30, end: 2*60))
  let overnight = scheduler.workoutWindow
  precondition(overnight.isSlot(minute: 30, interval: 60))
  precondition(overnight.contains(minute: 119) && !overnight.contains(minute: 120))
  precondition(!overnight.contains(minute: 12*60))
  for name in ["BlinkStart", "BlinkHalfway", "BlinkComplete", "BlinkPreview"] {
      precondition(NSSound(contentsOf: CuePlayer.soundURL(name), byReference: false) != nil)
  }
  print("PASS: custom and overnight windows, exclusive end, persistence, invalid input, audio decoding")
  var snoozes = 0; var dismissals = 0; var completed = 0; var cues: [ReminderCue] = []
  for kind in ReminderKind.allCases {
   let view = CompanionReminderView(kind: kind, dismiss: { dismissals += 1 }, snooze: { snoozes += 1 }, playCue: {_ in})
   let later = view.subviews.compactMap { $0 as? NSButton }.first { $0.title == "In 10 minutes" }!
   later.performClick(nil)
  }
  precondition(snoozes == 3 && dismissals == 3)
  let eye = CompanionReminderView(kind: .eyes, dismiss: {}, snooze: {}, playCue: { cues.append($0); if $0 == .complete { completed += 1 } })
  let start = eye.subviews.compactMap { $0 as? NSButton }.first { $0.title == "Start break" }!
  start.performClick(nil)
  precondition(start.title == "Resting…" && !start.isEnabled)
  precondition(cues == [.start])
  RunLoop.current.run(until: Date().addingTimeInterval(10.6))
  precondition(cues == [.start, .halfway])
  RunLoop.current.run(until: Date().addingTimeInterval(10.0))
  precondition(start.title == "Done" && start.isEnabled && completed == 1)
  precondition(cues == [.start, .halfway, .complete])
  print("PASS: three cues at 20, 10 and 0 seconds; all three snooze actions; eye break starts, completes, and emits one completion cue")
 }
}
