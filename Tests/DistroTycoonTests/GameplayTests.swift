@testable import DistroTycoon
import Testing

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
    #expect(game.log.count > 0)
    #expect(game.log[0].hasPrefix("[Day "))
}

@Test func namingAndReleasingAreLogged() throws {
    let game = try makeGame()
    game.nameDistro("Tuxedo")
    game.setIncluded(true, try #require(game.repository.package(id: "qde")))
    #expect(game.log == ["[Day 0] Started work on Tuxedo."])
    let message = game.release()
    #expect(game.log.last == "[Day 0] \(message)")
}

@Test func theLogKeepsOnlyItsNewestEntries() throws {
    let game = try makeGame()
    game.nameDistro("Tuxedo")
    game.setIncluded(true, try #require(game.repository.package(id: "qde")))
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

@Test func eachReleaseCountsUp() {
    let distro = UserDistro()
    distro.nameDistro(name: "Tuxedo")
    #expect(distro.makeNewRelease() == "1.0 of Tuxedo has been released! Time to sit back and relax")
    #expect(distro.makeNewRelease(isLTS: true) == "2.0 LTS of Tuxedo has been released! Time to sit back and relax")
}

@Test func chanceCardAddsHypeOnlyWhenItHasAMessage() {
    var generator = SeededGenerator(state: 2000)
    var messages = 0
    var misses = 0
    for _ in 0 ..< 5000 {
        let distro = UserDistro()
        if chanceCard(distro: distro, using: &generator) == nil {
            #expect(distro.buzz == 0)
            misses += 1
        } else {
            #expect(distro.buzz == 5)
            messages += 1
        }
    }
    #expect(messages > 0)
    #expect(misses > 0)
}
