@testable import DistroTycoon
import Testing

/// A named game with a desktop environment and a few buggy packages, ready to release.
private func makeGame(packages: [String] = ["qde", "okayoffice", "lunarblackout"]) throws -> Game {
    let game = try Game(repository: Resources.loadRepository())
    game.nameDistro("Tuxedo")
    for id in packages {
        game.setIncluded(true, try #require(game.repository.package(id: id)))
    }
    return game
}

private func run(_ game: Game, days: Int, seed: UInt64 = 7) {
    var generator = SeededGenerator(state: seed)
    for _ in 0 ..< days {
        game.advanceDay(using: &generator)
    }
}

/// Plays until an issue is open, so tests can work on one.
private func runUntilAnIssue(_ game: Game) throws -> ReportedIssue {
    var generator = SeededGenerator(state: 11)
    for _ in 0 ..< 1_000 where game.openIssues.isEmpty {
        game.advanceDay(using: &generator)
    }
    return try #require(game.openIssues.first)
}

@Test func nothingHappensToUsersOrIssuesBeforeTheFirstRelease() throws {
    let game = try makeGame()
    run(game, days: 200)
    #expect(game.openIssues.isEmpty)
    #expect(game.distro.users == 0)
    #expect(game.versionLabel == "Unreleased")
}

@Test func aReleaseBringsUsersAndIssues() throws {
    let game = try makeGame()
    _ = game.release()
    run(game, days: 200)
    #expect(game.distro.users > 0)
    #expect(!game.openIssues.isEmpty)
}

@Test func aFixTakesItsEffortAndShipsOnlyWithARelease() throws {
    let game = try makeGame()
    _ = game.release()
    let issue = try runUntilAnIssue(game)
    #expect(game.startFixing(issueID: issue.id) == nil)
    #expect(game.startFixing(issueID: issue.id) == "Finish the fix in progress first.")
    var generator = SeededGenerator(state: 3)
    for _ in 0 ..< issue.effort {
        #expect(!game.fixedIssues.contains(issue))
        game.advanceDay(using: &generator)
    }
    #expect(game.fixedIssues.contains(issue))
    #expect(game.fix == nil)
    _ = game.release()
    #expect(game.fixedIssues.isEmpty)
    #expect(game.log.contains { $0.contains("It ships") })
}

@Test func fixingAnIssueThatIsntOpenIsRefused() throws {
    let game = try makeGame()
    #expect(game.startFixing(issueID: 999) == "That issue isn't open.")
}

@Test func releasingAgainSoonEarnsLessBuzz() throws {
    let rested = try makeGame()
    _ = rested.release()
    let restedBuzz = rested.distro.buzz

    let hasty = try makeGame()
    _ = hasty.release()
    _ = hasty.release()
    #expect(hasty.distro.buzz - restedBuzz < restedBuzz)
}

@Test func rollingShipsChangesTheNextDay() throws {
    let game = try makeGame(packages: ["qde"])
    game.setCycle(.rolling)
    #expect(game.release() == "Rolling releases ship changes as you go.")
    run(game, days: 1)
    #expect(game.versionLabel == "Rolling")
    #expect(game.shippedPackages.contains("qde"))
    game.setIncluded(true, try #require(game.repository.package(id: "okayoffice")))
    run(game, days: 1)
    #expect(game.shippedPackages.contains("okayoffice"))
}

@Test func rollingFixesShipTheNextDay() throws {
    let game = try makeGame()
    game.setCycle(.rolling)
    run(game, days: 1)
    let issue = try runUntilAnIssue(game)
    game.startFixing(issueID: issue.id)
    var generator = SeededGenerator(state: 5)
    for _ in 0 ... issue.effort {
        game.advanceDay(using: &generator)
    }
    #expect(game.fixedIssues.isEmpty)
}

@Test func predictableReleasesWaitForTheirWindow() throws {
    let game = try makeGame()
    game.setCycle(.predictable)
    #expect(game.dueDay == Rules.releaseInterval)
    #expect(game.releaseProblem?.hasPrefix("The next release is due on day") == true)
    run(game, days: Rules.releaseInterval - Rules.releaseWindow)
    #expect(game.releaseProblem == nil)
    _ = game.release()
    #expect(game.dueDay == Rules.releaseInterval * 2)
    #expect(game.supportEndDay == game.day + Rules.standardSupport)
}

@Test func aMissedDateMakesNewsOnce() throws {
    let game = try makeGame()
    game.setCycle(.predictable)
    run(game, days: Rules.releaseInterval + 5)
    #expect(game.log.filter { $0.contains("missed its release date") }.count == 1)
    _ = game.release()
    #expect(game.dueDay.map { $0 > game.day } == true)
}

@Test func droppingAPackageOnAScheduleMakesNews() throws {
    let game = try makeGame()
    game.setCycle(.predictable)
    run(game, days: Rules.releaseInterval - Rules.releaseWindow)
    _ = game.release()
    game.setIncluded(false, try #require(game.repository.package(id: "okayoffice")))
    run(game, days: Rules.releaseInterval)
    _ = game.release()
    #expect(game.log.contains { $0.contains("broke things by dropping OkayOffice") })
}

@Test func everyFourthScheduledReleaseIsLTSWhenChosen() throws {
    let game = try makeGame()
    game.setCycle(.predictable)
    game.setIncludesLTS(true)
    var labels: [String] = []
    for _ in 0 ..< Rules.ltsEvery {
        run(game, days: (game.dueDay ?? 0) - game.day)
        _ = game.release()
        labels.append(game.versionLabel)
    }
    #expect(labels == ["Version 1.0", "Version 2.0", "Version 3.0", "Version 4.0 LTS"])
    #expect(game.supportEndDay == game.day + Rules.ltsSupport)
}

@Test func endOfSupportMakesNewsAndCostsUsers() throws {
    let game = try makeGame()
    game.setCycle(.predictable)
    run(game, days: Rules.releaseInterval - Rules.releaseWindow)
    _ = game.release()
    run(game, days: Rules.standardSupport + 1)
    #expect(game.log.contains { $0.contains("is no longer supported") })
}

@Test func switchingCyclesAfterShippingMakesNews() throws {
    let game = try makeGame()
    game.setCycle(.rolling)
    #expect(game.log.last?.contains("will use rolling releases") == true)
    run(game, days: 1)
    let buzz = game.distro.buzz
    game.setCycle(.noSchedule)
    #expect(game.log.last?.contains("News: Tuxedo switches to no schedule releases.") == true)
    #expect(game.distro.buzz == buzz - Rules.cycleSwitchBuzz)
}

@Test func ltsCanOnlyBeChosenOnAPredictableSchedule() throws {
    let game = try makeGame()
    game.setIncludesLTS(true)
    #expect(!game.includesLTS)
}

@Test(arguments: [1, 2, 3, 4] as [UInt64])
func anActivePlayerDoesBetterThanANeglectfulOne(seed: UInt64) throws {
    let neglectful = try makeGame()
    _ = neglectful.release()
    run(neglectful, days: 365, seed: seed)

    let active = try makeGame()
    _ = active.release()
    var generator = SeededGenerator(state: seed)
    for day in 1 ... 365 {
        active.advanceDay(using: &generator)
        if active.fix == nil, let easiest = active.openIssues.min(by: { $0.effort < $1.effort }) {
            active.startFixing(issueID: easiest.id)
        }
        if day % 30 == 0 {
            _ = active.release()
        }
    }

    #expect(active.distro.users > neglectful.distro.users)
    #expect(neglectful.openIssues.count <= Rules.openIssueLimit)
    #expect(neglectful.distro.users >= 0)
}
