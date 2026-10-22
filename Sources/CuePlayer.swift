import AppKit

enum ReminderCue: Equatable {
    case nudge, start, halfway, complete
    func filename(in set: SoundSet) -> String {
        switch self {
        case .nudge, .start: return set.filePrefix + "Start"
        case .halfway: return set.filePrefix + "Halfway"
        case .complete: return set.filePrefix + "Complete"
        }
    }
}

enum SoundSet: String, CaseIterable {
    case bells, marimba, chimes, kalimba, woodblock

    var title: String {
        switch self {
        case .bells: "Soft Bells"
        case .marimba: "Marimba"
        case .chimes: "Wind Chimes"
        case .kalimba: "Kalimba"
        case .woodblock: "Woodblock"
        }
    }
    // The original bells keep their Blink* filenames, which the Windows build also embeds.
    var filePrefix: String {
        switch self {
        case .bells: "Blink"
        case .marimba: "Marimba"
        case .chimes: "Chimes"
        case .kalimba: "Kalimba"
        case .woodblock: "Woodblock"
        }
    }
    var previewFilename: String { filePrefix + "Preview" }
}

final class CuePlayer {
    private var current: NSSound?
    static func soundURL(_ filename: String) -> URL {
        Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: "Sounds")
            ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets/Sounds/\(filename).wav")
    }
    func play(_ cue: ReminderCue, in set: SoundSet) { playFile(cue.filename(in: set)) }
    /// Blink demonstrates all three break cues; the other buddies only use the nudge.
    func preview(_ set: SoundSet, fullSequence: Bool) { playFile(fullSequence ? set.previewFilename : ReminderCue.nudge.filename(in: set)) }
    private func playFile(_ filename: String) {
        current?.stop()
        guard let sound = NSSound(contentsOf: Self.soundURL(filename), byReference: false) else { return }
        sound.volume = 0.65
        current = sound
        sound.play()
    }
}
