import Foundation

struct WorkoutWindow: Equatable {
    let start: Int
    let end: Int
    static let standard = WorkoutWindow(start: 14 * 60, end: 18 * 60)!

    init?(start: Int, end: Int) {
        guard (0..<1440).contains(start), (0..<1440).contains(end), start != end else { return nil }
        self.start = start
        self.end = end
    }

    var crossesMidnight: Bool { end < start }
    func contains(minute: Int) -> Bool {
        if crossesMidnight { return minute >= start || minute < end }
        return minute >= start && minute < end
    }
    func isSlot(minute: Int, interval: Int) -> Bool {
        guard interval > 0, contains(minute: minute) else { return false }
        return ((minute - start + 1440) % 1440) % interval == 0
    }
    var summary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        func time(_ minute: Int) -> String {
            formatter.string(from: Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: minute / 60, minute: minute % 60))!)
        }
        return "\(time(start))–\(time(end))"
    }
}

extension Notification.Name {
    static let pippySettingsChanged = Notification.Name("pippySettingsChanged")
}
