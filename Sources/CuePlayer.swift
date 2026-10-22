import AppKit

enum ReminderCue: Equatable {
    case nudge, start, halfway, complete
    var filename: String {
        switch self {
        case .nudge, .start: return "BlinkStart"
        case .halfway: return "BlinkHalfway"
        case .complete: return "BlinkComplete"
        }
    }
}

final class CuePlayer {
    private var current: NSSound?
    static func soundURL(_ filename: String) -> URL {
        Bundle.main.url(forResource: filename, withExtension: "wav", subdirectory: "Sounds")
            ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Assets/Sounds/\(filename).wav")
    }
    func play(_ cue: ReminderCue) { playFile(cue.filename) }
    func preview() { playFile("BlinkPreview") }
    private func playFile(_ filename: String) {
        current?.stop()
        guard let sound = NSSound(contentsOf: Self.soundURL(filename), byReference: false) else { return }
        sound.volume = 0.65
        current = sound
        sound.play()
    }
}
