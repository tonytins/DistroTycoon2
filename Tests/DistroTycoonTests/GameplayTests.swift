@testable import DistroTycoon
import Testing

// A fixed sequence, so a failing roll can be repeated.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
        return state
    }
}

private func makeGame() throws -> Game {
    try Game(repository: Resources.loadRepository())
}

@Test func eachDayCountsUpAndLogsWhatHappened() throws {
    let game = try makeGame()
    var generator = SeededGenerator(state: 2000)
    for day in 1 ... 400 {
        game.advanceDay(using: &generator)
        #expect(game.day == day)
    }
    #expect(!game.log.isEmpty)
    #expect(game.distro.hype == game.log.count * 5)
    #expect(game.log[0].hasPrefix("[Day "))
}

@Test func namingAndReleasingAreLogged() throws {
    let game = try makeGame()
    game.nameDistro("Tuxedo")
    #expect(game.log == ["[Day 0] Started work on Tuxedo."])
    let message = game.release()
    #expect(game.log.last == "[Day 0] \(message)")
}

@Test func theLogKeepsOnlyItsNewestEntries() throws {
    let game = try makeGame()
    game.nameDistro("Tuxedo")
    for _ in 1 ... 600 {
        _ = game.release()
    }
    #expect(game.log.count == 500)
    #expect(game.log.last?.contains("600.0 of Tuxedo") == true)
}

@Test func clearingTheLogIsNoticedByItsRevision() throws {
    let game = try makeGame()
    game.nameDistro("Tuxedo")
    let revision = game.logRevision
    game.clearLog()
    #expect(game.log.isEmpty)
    #expect(game.logRevision != revision)
}

@Test func aNewDistroIsUnreleasedAndEachReleaseCountsUp() {
    let distro = UserDistro()
    distro.nameDistro(name: "Tuxedo")
    #expect(distro.versionLabel == "Unreleased")
    #expect(distro.makeNewRelease() == "1.0 of Tuxedo has been released! Time to sit back and relax")
    #expect(distro.versionLabel == "Version 1.0")
    #expect(distro.makeNewRelease() == "2.0 of Tuxedo has been released! Time to sit back and relax")
}

@Test func chanceCardAddsHypeOnlyWhenItHasAMessage() {
    var generator = SeededGenerator(state: 2000)
    var messages = 0
    var misses = 0
    for _ in 0 ..< 5000 {
        let distro = UserDistro()
        if chanceCard(distro: distro, using: &generator) == nil {
            #expect(distro.hype == 0)
            misses += 1
        } else {
            #expect(distro.hype == 5)
            messages += 1
        }
    }
    #expect(messages > 0)
    #expect(misses > 0)
}
