/// How a distro releases. Each cycle has its own risks.
enum ReleaseCycle: CaseIterable, Equatable {
    /// The classic way: release whenever you like, but releasing again soon earns little buzz.
    case noSchedule
    /// Changes reach users the day after they're made, and fixes can bring regressions.
    case rolling
    /// Releases are due on a schedule. A missed date or a dropped package makes news.
    case predictable

    var title: String {
        switch self {
        case .noSchedule: "No schedule"
        case .rolling: "Rolling"
        case .predictable: "Predictable"
        }
    }
}

/// A problem reported against a shipped package.
struct ReportedIssue: Equatable {
    let id: Int
    let packageID: String
    let summary: String
    /// Days of work to fix it.
    let effort: Int
}

/// What a release shipped.
struct ShippedRelease: Equatable {
    let version: Int
    let day: Int
    let isLTS: Bool
    let packages: Set<String>
}

/// The numbers behind the rules. All are test values until the game is balanced.
enum Rules {
    static let logLimit = 500
    static let openIssueLimit = 60
    /// The daily chance of an issue, per point of a shipped package's bugginess.
    static let issueChance = 0.004
    /// Users that double how often issues arrive.
    static let usersDoublingIssues = 1_000.0
    /// Users that add one more lost user per open shipped bug each day.
    static let usersPerBugCost = 400
    static let starsPerUser = 250
    static let regressionChance = 0.15
    static let releaseInterval = 60
    static let releaseWindow = 14
    static let ltsEvery = 4
    static let standardSupport = 120
    static let ltsSupport = 360
    static let unsupportedLossPercent = 1
    static let cycleSwitchBuzz = 5
    static let missedDateBuzz = 10
    static let breakingChangeBuzz = 8
}

/// Everything the simulation knows. It has no interface, so tests can run it without a window.
final class Game {
    let repository: Repository
    let distro = UserDistro()
    private(set) var day = 0
    /// What has happened, oldest first. Only the newest entries are kept.
    private(set) var log: [String] = []
    /// Changes whenever `log` does, so an interface can tell cheaply that it should catch up.
    private(set) var logRevision = 0

    /// The packages chosen for the next release, by id.
    private(set) var includedPackages: Set<String>
    /// The packages users have, by id.
    private(set) var shippedPackages: Set<String> = []
    /// Changes whenever the chosen packages do.
    private(set) var packagesRevision = 0

    private(set) var cycle: ReleaseCycle = .noSchedule
    /// Whether a predictable schedule makes every fourth release an LTS.
    private(set) var includesLTS = false
    /// The day the next predictable release is due.
    private(set) var dueDay: Int?
    private(set) var latestRelease: ShippedRelease?
    private(set) var stars = 0

    /// Issues waiting for a fix, oldest first.
    private(set) var openIssues: [ReportedIssue] = []
    /// The issue being fixed, and the days of work left on it.
    private(set) var fix: (issue: ReportedIssue, daysLeft: Int)?
    /// Fixed issues that users won't have until the next release.
    private(set) var fixedIssues: [ReportedIssue] = []
    /// Changes whenever the issues do.
    private(set) var issuesRevision = 0

    private var lastIssueID = 0
    private var scheduledReleases = 0
    private var hasMissedDueDay = false
    private var hasReportedEndOfSupport = false

    init(repository: Repository) {
        self.repository = repository
        includedPackages = Set(repository.packages.filter(\.isPreinstalled).map(\.id))
    }

    // MARK: - Packages

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

    // MARK: - Releases

    /// Whether the distro has reached users yet.
    var hasShipped: Bool {
        latestRelease != nil
    }

    /// Whether the next predictable release will be an LTS.
    var nextReleaseIsLTS: Bool {
        cycle == .predictable && includesLTS && (scheduledReleases + 1) % Rules.ltsEvery == 0
    }

    /// The version as the player reads it.
    var versionLabel: String {
        guard let latestRelease else {
            return "Unreleased"
        }
        if cycle == .rolling {
            return "Rolling"
        }
        return "Version \(latestRelease.version).0\(latestRelease.isLTS ? " LTS" : "")"
    }

    /// Why the distro can't be released right now, or `nil` when it can.
    var releaseProblem: String? {
        if distro.distroName.isEmpty {
            return "Name your distro first."
        }
        if !hasDesktop(includedPackages) {
            return "Add a desktop environment in Packages first."
        }
        if cycle == .rolling {
            return "Rolling releases ship changes as you go."
        }
        if cycle == .predictable, let dueDay, day < dueDay - Rules.releaseWindow {
            return "The next release is due on day \(dueDay). Its window opens on day \(dueDay - Rules.releaseWindow)."
        }
        return nil
    }

    /// The day the latest release stops being supported, on a predictable schedule.
    var supportEndDay: Int? {
        guard cycle == .predictable, let latestRelease else {
            return nil
        }
        return latestRelease.day + (latestRelease.isLTS ? Rules.ltsSupport : Rules.standardSupport)
    }

    /// Releases the next version with the chosen packages and fixes, and returns the message to
    /// show the player. When `releaseProblem` isn't `nil`, nothing is released and it's returned.
    func release() -> String {
        if let releaseProblem {
            return releaseProblem
        }
        let isLTS = nextReleaseIsLTS
        let dropped = latestRelease.map { $0.packages.subtracting(includedPackages) } ?? []
        let wasLTS = latestRelease?.isLTS ?? false
        let daysSinceLast = latestRelease.map { day - $0.day } ?? Rules.releaseInterval

        switch cycle {
        case .noSchedule:
            distro.buzz += min(10, 2 + (daysSinceLast / 6))
        case .predictable:
            distro.buzz += hasMissedDueDay ? 3 : (isLTS ? 12 : 8)
            scheduledReleases += 1
            hasMissedDueDay = false
            if var due = dueDay {
                repeat {
                    due += Rules.releaseInterval
                } while due <= day
                dueDay = due
            }
        case .rolling:
            break
        }

        let shippedFixes = fixedIssues.count
        fixedIssues.removeAll()
        issuesRevision += 1
        shippedPackages = includedPackages
        hasReportedEndOfSupport = false
        var message = distro.makeNewRelease(isLTS: isLTS)
        latestRelease = ShippedRelease(version: distro.distroVersion, day: day, isLTS: isLTS, packages: includedPackages)
        if shippedFixes > 0 {
            message += " It ships \(shippedFixes) fix\(shippedFixes == 1 ? "" : "es")."
        }
        record(message)

        if cycle == .predictable, !dropped.isEmpty {
            distro.buzz -= Rules.breakingChangeBuzz * (isLTS || wasLTS ? 2 : 1)
            let names = repository.packages.filter { dropped.contains($0.id) }.map(\.name).joined(separator: ", ")
            record("News: \(distro.distroName) broke things by dropping \(names).")
        }
        return message
    }

    /// Changes how the distro releases. Once it has shipped, a switch makes news and costs buzz.
    func setCycle(_ cycle: ReleaseCycle) {
        guard !distro.distroName.isEmpty, cycle != self.cycle else {
            return
        }
        self.cycle = cycle
        dueDay = cycle == .predictable ? day + Rules.releaseInterval : nil
        hasMissedDueDay = false
        issuesRevision += 1
        if hasShipped {
            distro.buzz -= Rules.cycleSwitchBuzz
            record("News: \(distro.distroName) switches to \(cycle.title.lowercased()) releases.")
        } else {
            record("\(distro.distroName) will use \(cycle.title.lowercased()) releases.")
        }
    }

    /// Chooses whether a predictable schedule includes LTS releases.
    func setIncludesLTS(_ includesLTS: Bool) {
        guard cycle == .predictable, includesLTS != self.includesLTS else {
            return
        }
        self.includesLTS = includesLTS
        issuesRevision += 1
        record(includesLTS ? "Every \(Rules.ltsEvery)th release will be an LTS." : "No more LTS releases are planned.")
    }

    // MARK: - Issues

    /// Starts fixing an open issue, and returns why it can't be when it can't.
    @discardableResult
    func startFixing(issueID: Int) -> String? {
        guard fix == nil else {
            return "Finish the fix in progress first."
        }
        guard let index = openIssues.firstIndex(where: { $0.id == issueID }) else {
            return "That issue isn't open."
        }
        let issue = openIssues.remove(at: index)
        fix = (issue, issue.effort)
        issuesRevision += 1
        return nil
    }

    // MARK: - Days

    /// Moves the game on by one day.
    func advanceDay(using generator: inout some RandomNumberGenerator) {
        day += 1
        distro.buzz -= distro.buzz.signum()
        progressFix()
        if cycle == .rolling {
            shipRolling(using: &generator)
        }
        if hasShipped {
            reportIssues(using: &generator)
            updateUsers(using: &generator)
            stars += Int.random(in: 0 ... max(0, distro.users / Rules.starsPerUser), using: &generator)
        }
        checkSchedule()
        if let message = chanceCard(distro: distro, using: &generator) {
            record(message)
        }
    }

    /// Names the distro and notes that its project has started.
    func nameDistro(_ name: String) {
        distro.nameDistro(name: name)
        record("Started work on \(name).")
    }

    func clearLog() {
        log.removeAll()
        logRevision += 1
    }

    private func hasDesktop(_ packages: Set<String>) -> Bool {
        repository.packages.contains { $0.type == .desktopEnvironment && packages.contains($0.id) }
    }

    private func progressFix() {
        guard let fix else {
            return
        }
        guard fix.daysLeft <= 1 else {
            self.fix = (fix.issue, fix.daysLeft - 1)
            return
        }
        self.fix = nil
        fixedIssues.append(fix.issue)
        issuesRevision += 1
        record("Fixed #\(fix.issue.id). It reaches users with the next release.")
    }

    private func shipRolling(using generator: inout some RandomNumberGenerator) {
        guard !distro.distroName.isEmpty, hasDesktop(includedPackages) else {
            return
        }
        if latestRelease == nil {
            distro.distroVersion = max(distro.distroVersion, 1)
            record("\(distro.distroName) is rolling.")
        }
        shippedPackages = includedPackages
        latestRelease = ShippedRelease(version: distro.distroVersion, day: day, isLTS: false, packages: includedPackages)
        guard !fixedIssues.isEmpty else {
            return
        }
        let shipped = fixedIssues
        fixedIssues.removeAll()
        distro.buzz += min(3, shipped.count)
        for issue in shipped where Double.random(in: 0 ..< 1, using: &generator) < Rules.regressionChance {
            openIssue(for: issue.packageID, summary: "regressed after the fix for #\(issue.id)", using: &generator)
        }
        issuesRevision += 1
    }

    private func reportIssues(using generator: inout some RandomNumberGenerator) {
        let boost = 1 + (Double(distro.users) / Rules.usersDoublingIssues)
        for package in repository.packages where shippedPackages.contains(package.id) && package.bugginess > 0 {
            guard openIssues.count < Rules.openIssueLimit else {
                return
            }
            let chance = min(0.5, Double(package.bugginess) * Rules.issueChance * boost)
            if Double.random(in: 0 ..< 1, using: &generator) < chance {
                let summary = repository.issueTemplates.randomElement(using: &generator) ?? "has a bug"
                openIssue(for: package.id, summary: summary, using: &generator)
            }
        }
    }

    private func openIssue(for packageID: String, summary: String, using generator: inout some RandomNumberGenerator) {
        let bugginess = repository.package(id: packageID)?.bugginess ?? 1
        lastIssueID += 1
        openIssues.append(ReportedIssue(
            id: lastIssueID,
            packageID: packageID,
            summary: summary,
            effort: 1 + Int.random(in: 0 ... min(4, bugginess), using: &generator)
        ))
        issuesRevision += 1
    }

    private func updateUsers(using generator: inout some RandomNumberGenerator) {
        let shipped = repository.packages.filter { shippedPackages.contains($0.id) }
        let potential = shipped.reduce(0) { $0 + $1.appeal + $1.nerdCred }
        let gain = Int(Double.random(in: 0 ... 1, using: &generator) * Double(potential) / 2) + distro.buzz
        let shippedBugs = openIssues.count + (fix == nil ? 0 : 1) + fixedIssues.count
        var loss = shippedBugs * (1 + (distro.users / Rules.usersPerBugCost))
        if cycle == .predictable, latestRelease?.isLTS == true {
            loss /= 2
        }
        if let supportEndDay, day > supportEndDay {
            loss += distro.users * Rules.unsupportedLossPercent / 100
        }
        distro.users = max(0, distro.users + gain - loss)
    }

    private func checkSchedule() {
        if cycle == .predictable, let dueDay, day > dueDay, !hasMissedDueDay {
            hasMissedDueDay = true
            distro.buzz -= Rules.missedDateBuzz * (nextReleaseIsLTS ? 2 : 1)
            record("News: \(distro.distroName) missed its \(nextReleaseIsLTS ? "LTS " : "")release date.")
        }
        if let supportEndDay, day > supportEndDay, !hasReportedEndOfSupport {
            hasReportedEndOfSupport = true
            record("News: \(versionLabel) is no longer supported, and users are drifting away.")
        }
    }

    private func record(_ message: String) {
        log.append("[Day \(day)] \(message)")
        if log.count > Rules.logLimit {
            log.removeFirst(log.count - Rules.logLimit)
        }
        logRevision += 1
    }
}
