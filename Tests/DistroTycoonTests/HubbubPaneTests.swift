@testable import DistroTycoon
import Testing

private func makeShippedGame() throws -> Game {
    let game = try Game(repository: Resources.loadRepository())
    game.nameDistro("Tuxedo")
    game.setIncluded(true, try #require(game.repository.package(id: "qde")))
    game.setIncluded(true, try #require(game.repository.package(id: "lunarblackout")))
    _ = game.release()
    var generator = SeededGenerator(state: 21)
    for _ in 0 ..< 1_000 where game.openIssues.count < 2 {
        game.advanceDay(using: &generator)
    }
    return game
}

@Test func thePaneListsOpenIssuesAndFixesTheSelectedOne() throws {
    let game = try makeShippedGame()
    let pane = try HubbubPane(game: game)
    pane.refresh()
    #expect(pane.lines.count == game.openIssues.count)
    let second = game.openIssues[1]
    pane.selectIssue(at: 1)
    pane.press("fix")
    #expect(game.fix?.issue == second)
    #expect(!pane.lines.contains { $0.hasPrefix("#\(second.id) ") })
}

@Test func theFixButtonDoesNothingWithoutASelection() throws {
    let game = try makeShippedGame()
    let pane = try HubbubPane(game: game)
    pane.refresh()
    pane.press("fix")
    #expect(game.fix == nil)
}

@Test func theCycleButtonsSwitchCycles() throws {
    let game = try makeShippedGame()
    let pane = try HubbubPane(game: game)
    pane.press("predictable")
    #expect(game.cycle == .predictable)
    pane.press("lts")
    #expect(game.includesLTS)
    #expect(HubbubPane.schedule(for: game).hasPrefix("Next release due day"))
}

@Test func theHubbubLayoutLoadsCleanly() throws {
    #expect(try Resources.loadScript(named: "hubbub").ignoredAttributes.isEmpty)
}

@Test func anIssueLineNamesItsPackageAndEffort() throws {
    let game = try makeShippedGame()
    let issue = ReportedIssue(id: 7, packageID: "qde", summary: "eats all the memory", effort: 2)
    #expect(HubbubPane.line(for: issue, game: game) == "#7 QDE eats all the memory (2 days)")
}
