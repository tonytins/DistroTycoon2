/// The player's distro.
final class UserDistro {
    var distroName: String = ""
    /// Short-lived excitement, which fades a little each day and can go negative.
    var buzz: Int = 0
    var distroVersion: Int = 0
    var users: Int = 0

    func nameDistro(name: String) {
        distroName = name
    }

    /// Counts up to the next version and returns the message to show the player.
    func makeNewRelease(isLTS: Bool = false) -> String {
        distroVersion += 1
        let lts = isLTS ? " LTS" : ""
        return "\(distroVersion).0\(lts) of \(distroName) has been released! Time to sit back and relax"
    }
}

/// Rolls for a random event, applies it to `distro`, and returns the message to show the player, if any.
func chanceCard(distro: UserDistro, using generator: inout some RandomNumberGenerator) -> String? {
    let chance = Int.random(in: 1 ..< 35, using: &generator)

    if chance == 20 {
        distro.buzz += 5
        return "Your latest version got reviewed favorably in a major magazine!"
    }
    return nil
}
