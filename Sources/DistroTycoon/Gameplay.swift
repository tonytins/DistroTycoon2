/// Everything the simulation knows. It has no interface, so tests can run it without a window.
final class Game {
    private static let logLimit = 500

    let repository: Repository
    let distro = UserDistro()
    private(set) var day = 0
    /// What has happened, oldest first. Only the newest entries are kept.
    private(set) var log: [String] = []
    /// Changes whenever `log` does, so an interface can tell cheaply that it should catch up.
    private(set) var logRevision = 0

    /// The packages chosen for the next release, by id.
    private(set) var includedPackages: Set<String>
    /// The packages in the latest release, by id.
    private(set) var shippedPackages: Set<String> = []
    /// Changes whenever the chosen packages do.
    private(set) var packagesRevision = 0

    init(repository: Repository) {
        self.repository = repository
        includedPackages = Set(repository.packages.filter(\.isPreinstalled).map(\.id))
    }

    func isIncluded(_ package: Package) -> Bool {
        includedPackages.contains(package.id)
    }

    /// Adds or removes a package from the next release. A preinstalled package always stays.
    func setIncluded(_ isIncluded: Bool, _ package: Package) {
        guard !package.isPreinstalled, isIncluded != self.isIncluded(package) else {
            return
        }
        if isIncluded {
            includedPackages.insert(package.id)
        } else {
            includedPackages.remove(package.id)
        }
        packagesRevision += 1
    }

    /// Why the distro can't be released right now, or `nil` when it can.
    var releaseProblem: String? {
        if distro.distroName.isEmpty {
            return "Name your distro first."
        }
        let hasDesktop = repository.packages.contains { $0.type == .desktopEnvironment && isIncluded($0) }
        return hasDesktop ? nil : "Add a desktop environment in Packages first."
    }

    /// Moves the game on by one day.
    func advanceDay(using generator: inout some RandomNumberGenerator) {
        day += 1
        if let message = chanceCard(distro: distro, using: &generator) {
            record(message)
        }
    }

    /// Names the distro and notes that its project has started.
    func nameDistro(_ name: String) {
        distro.nameDistro(name: name)
        record("Started work on \(name).")
    }

    /// Releases the distro's next version with the chosen packages, and returns the message to
    /// show the player. When `releaseProblem` isn't `nil`, nothing is released and it's returned.
    func release() -> String {
        if let releaseProblem {
            return releaseProblem
        }
        shippedPackages = includedPackages
        let message = distro.makeNewRelease()
        record(message)
        return message
    }

    func clearLog() {
        log.removeAll()
        logRevision += 1
    }

    private func record(_ message: String) {
        log.append("[Day \(day)] \(message)")
        if log.count > Self.logLimit {
            log.removeFirst(log.count - Self.logLimit)
        }
        logRevision += 1
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
