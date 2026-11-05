/// How fast game days pass.
enum GameSpeed: CaseIterable, Equatable {
    case paused
    case normal
    case fast

    /// Real seconds per game day, or `nil` while paused.
    var secondsPerDay: Double? {
        switch self {
        case .paused: nil
        case .normal: 2
        case .fast: 0.5
        }
    }
}

/// Turns real time into whole game days.
struct GameClock {
    // A long stall, such as a dragged window or a debugger, shouldn't dump a pile of days at once.
    private static let longestStep: Double = 0.25

    var speed: GameSpeed
    private var carried: Double = 0

    init(speed: GameSpeed = .paused) {
        self.speed = speed
    }

    /// Adds `seconds` of real time and returns how many days have passed.
    mutating func advance(by seconds: Double) -> Int {
        guard let secondsPerDay = speed.secondsPerDay, seconds.isFinite, seconds > 0 else {
            return 0
        }
        carried += min(seconds, Self.longestStep)
        let days = Int(carried / secondsPerDay)
        carried -= Double(days) * secondsPerDay
        return days
    }
}
