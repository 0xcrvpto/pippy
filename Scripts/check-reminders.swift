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
  let time = ScrollPickerChip(values: ActiveHoursView.quarterHours, selected: 23*60+45, wraps: true, tint: Palette.coral, format: formatMinuteOfDay)
  time.onChange = { picked.append($0) }
  precondition(time.step(by: 1) && time.value == 0)
  precondition(time.step(by: -2) && time.value == 23*60+30)
  time.skip = { $0 == 23*60+45 }
  precondition(time.step(by: 1) && time.value == 0)
  precondition(picked == [0, 23*60+30, 0])
  let interval = ScrollPickerChip(values: Array(stride(from: 5, through: 60, by: 5)), selected: 60, wraps: false, tint: Palette.lilac) { "\($0) min" }
  precondition(!interval.step(by: 1) && interval.value == 60)
  precondition(interval.step(by: -3) && interval.value == 45)
  let prefs = PreferencesView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 560, height: 780))
  let hours = prefs.subviews.compactMap { $0 as? ActiveHoursView }.first!
  let rally = hours.chips[.workout]!
  rally.start.select(17*60); rally.end.select(17*60+15)
  precondition(rally.end.step(by: -1) && rally.end.value == 16*60+45)
  precondition(scheduler.workoutWindow == WorkoutWindow(start: 17*60, end: 16*60+45))
  // Blink and Mochi default to 11 AM–11 PM, change independently, and persist.
  precondition(scheduler.activeHours(for: .eyes) == WorkoutWindow(start: 660, end: 1380) && scheduler.activeHours(for: .stretch) == WorkoutWindow(start: 660, end: 1380))
  precondition(hours.chips[.eyes]!.start.step(by: -8) && scheduler.activeHours(for: .eyes) == WorkoutWindow(start: 540, end: 1380))
  precondition(scheduler.activeHours(for: .stretch) == WorkoutWindow(start: 660, end: 1380) && scheduler.workoutWindow == WorkoutWindow(start: 17*60, end: 16*60+45))
  precondition(scheduler.setActiveHours(start: 22*60, end: 6*60, for: .stretch) && !scheduler.setActiveHours(start: 60, end: 60, for: .stretch))
  precondition(ReminderScheduler(defaults: defaults, startTimer: false).activeHours(for: .stretch) == WorkoutWindow(start: 22*60, end: 6*60))
  precondition(ReminderScheduler(defaults: defaults, startTimer: false).activeHours(for: .eyes).start == 540)
  print("PASS: scroll picker wraps midnight, skips the matching time, clamps intervals; each buddy's active hours save independently and persist")
  let mail = Feedback.emailURL().absoluteString
  precondition(mail.hasPrefix("mailto:0xcrvpto@webuild3.xyz?") && mail.contains("subject=Pippy%20feedback") && mail.contains("body=") && !mail.contains(" "))
  precondition(Feedback.telegram.absoluteString == "https://t.me/i0xcrvpto")
  precondition(Feedback.menu().items.count == 2)
  print("PASS: feedback email link and Telegram link")
  precondition(Updates.isNewer("v0.6.1", than: "0.6") && Updates.isNewer("0.10", than: "0.9.9") && !Updates.isNewer("v0.6.1", than: "0.6.1") && !Updates.isNewer("0.6", than: "0.6.1"))
  let sample = #"{"tag_name":"v0.7.0","html_url":"https://github.com/0xcrvpto/pippy/releases/tag/v0.7.0","draft":false,"prerelease":false,"assets":[{"name":"Pippy-0.7-Windows-x64-Setup.exe","browser_download_url":"https://example.com/win.exe"},{"name":"Pippy-0.7-arm64.dmg","browser_download_url":"https://example.com/mac.dmg"}]}"#
  let release = Updates.parse(Data(sample.utf8))!
  precondition(release.version == "0.7.0" && release.download.absoluteString == "https://example.com/mac.dmg" && release.page.absoluteString.hasSuffix("v0.7.0"))
  let pageOnly = Updates.parse(Data(#"{"tag_name":"v0.8","html_url":"https://github.com/0xcrvpto/pippy/releases/tag/v0.8","assets":[]}"#.utf8))!
  precondition(pageOnly.download == pageOnly.page)
  precondition(Updates.parse(Data(#"{"tag_name":"v0.9","html_url":"https://x.y","prerelease":true}"#.utf8)) == nil && Updates.parse(Data("nope".utf8)) == nil)
  let dashboard = DashboardView(scheduler: scheduler, frame: NSRect(x: 0, y: 0, width: 960, height: 660))
  precondition(dashboard.updateBanner.isHidden)
  dashboard.showUpdate(release)
  precondition(!dashboard.updateBanner.isHidden)
  print("PASS: update version comparison, release parsing with Mac asset and page fallback, banner shows")
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
