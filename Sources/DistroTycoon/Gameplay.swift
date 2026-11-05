/// Everything the simulation knows. It has no interface, so tests can run it without a window.
final class Game {
    let repository: Repository
    let distro = UserDistro()
    private(set) var day = 0

    init(repository: Repository) {
        self.repository = repository
    }

    /// Moves the game on by one day and returns what the player should be told.
    func advanceDay(using generator: inout some RandomNumberGenerator) -> [String] {
        day += 1
        return [chanceCard(distro: distro, using: &generator)].compactMap(\.self)
    }
}

class UserDistro {
    var distroName: String = ""
    var hype: Int = 0
    var distroVersion: Int = 0
    var users: Int = 0

    func nameDistro(name: String) {
        distroName = name
    }

    func updateHype(hype: Int) {
        self.hype += hype
    }

    /// The version the player has shipped, for showing in the interface.
    var versionLabel: String {
        distroVersion == 0 ? "Unreleased" : "Version \(distroVersion).0"
    }

    /// Releases the next version and returns the message to show the player.
    func makeNewRelease() -> String {
        distroVersion += 1
        return "\(distroVersion).0 of \(distroName) has been released! Time to sit back and relax"
    }
}

/// Rolls for a random event, applies it to `distro`, and returns the message to show the player, if any.
func chanceCard(distro: UserDistro, using generator: inout some RandomNumberGenerator) -> String? {
    let chance = Int.random(in: 1 ..< 35, using: &generator)

    if chance == 20 {
        distro.hype += 5
        return "Your latest version got reviewed favorably in a major magazine!"
    }
    return nil
}
