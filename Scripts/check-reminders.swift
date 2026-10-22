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
  for set in SoundSet.allCases {
   for name in [ReminderCue.start, .halfway, .complete].map({ $0.filename(in: set) }) + [set.previewFilename] {
      precondition(NSSound(contentsOf: CuePlayer.soundURL(name), byReference: false) != nil, "missing \(name)")
   }
  }
  precondition(ReminderCue.halfway.filename(in: .bells) == "BlinkHalfway")
  print("PASS: custom and overnight windows, exclusive end, persistence, invalid input, audio decoding for every sound set")
  precondition(scheduler.soundSet(for: .eyes) == .bells && scheduler.soundSet(for: .workout) == .marimba && scheduler.soundSet(for: .stretch) == .kalimba)
  scheduler.setSoundSet(.woodblock, for: .stretch)
  precondition(ReminderScheduler(defaults: defaults, startTimer: false).soundSet(for: .stretch) == .woodblock)
  precondition(scheduler.soundSet(for: .eyes) == .bells)
  print("PASS: per-buddy sound defaults, independent choice, persistence")
  var picked: [Int] = []
  let time = ScrollPickerChip(values: WorkoutHoursView.quarterHours, selected: 23*60+45, wraps: true, tint: Palette.coral, format: formatMinuteOfDay)
  time.onChange = { picked.append($0) }
  precondition(time.step(by: 1) && time.value == 0)
  precondition(time.step(by: -2) && time.value == 23*60+30)
  time.skip = { $0 == 23*60+45 }
  precondition(time.step(by: 1) && time.value == 0)
  precondition(picked == [0, 23*60+30, 0])
  let interval = ScrollPickerChip(values: Array(stride(from: 5, through: 60, by: 5)), selected: 60, wraps: false, tint: Palette.lilac) { "\($0) min" }
  precondition(!interval.step(by: 1) && interval.value == 60)
  precondition(interval.step(by: -3) && interval.value == 45)
  let prefs = PreferencesView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 560, height: 716))
  let hours = prefs.subviews.compactMap { $0 as? WorkoutHoursView }.first!
  hours.startChip.select(17*60); hours.endChip.select(17*60+15)
  precondition(hours.endChip.step(by: -1) && hours.endChip.value == 16*60+45)
  precondition(scheduler.workoutWindow == WorkoutWindow(start: 17*60, end: 16*60+45))
  print("PASS: scroll picker wraps midnight, skips the matching time, clamps intervals, and saves workout hours")
  let mail = Feedback.emailURL().absoluteString
  precondition(mail.hasPrefix("mailto:0xcrvpto@webuild3.xyz?") && mail.contains("subject=Pippy%20feedback") && mail.contains("body=") && !mail.contains(" "))
  precondition(Feedback.telegram.absoluteString == "https://t.me/i0xcrvpto")
  precondition(Feedback.menu().items.count == 2)
  print("PASS: feedback email link and Telegram link")
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
