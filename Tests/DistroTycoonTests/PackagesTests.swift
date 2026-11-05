@testable import DistroTycoon
import Testing

private func makeGame() throws -> Game {
    let game = try Game(repository: Resources.loadRepository())
    game.nameDistro("Tuxedo")
    return game
}

@Test func aNewGameShipsOnlyWhatsPreinstalled() throws {
    let game = try makeGame()
    #expect(game.includedPackages == ["hubbub"])
}

@Test func releasingNeedsADesktopEnvironmentAndShipsTheChoices() throws {
    let game = try makeGame()
    let message = game.release()
    #expect(message == "Add a desktop environment in Packages first.")
    #expect(game.distro.distroVersion == 0)

    let desktop = try #require(game.repository.package(id: "qde"))
    game.setIncluded(true, desktop)
    #expect(game.releaseProblem == nil)
    _ = game.release()
    #expect(game.distro.distroVersion == 1)
    #expect(game.shippedPackages == ["hubbub", "qde"])
}

@Test func releasingNeedsAName() throws {
    let game = try Game(repository: Resources.loadRepository())
    #expect(game.releaseProblem == "Name your distro first.")
}

@Test func aPreinstalledPackageCantBeRemoved() throws {
    let game = try makeGame()
    let hubbub = try #require(game.repository.package(id: "hubbub"))
    let revision = game.packagesRevision
    game.setIncluded(false, hubbub)
    #expect(game.isIncluded(hubbub))
    #expect(game.packagesRevision == revision)
}

@Test func thePackageManagerTogglesTheShownPackage() throws {
    let game = try makeGame()
    let manager = try PackageManagerApp(game: game)
    let shown = try #require(manager.selectedPackage)
    #expect(!game.isIncluded(shown))
    manager.toggleSelected()
    #expect(game.isIncluded(shown))
    manager.refresh()
    #expect(manager.lines[0] == "[x] \(shown.name)")
    #expect(manager.lines.contains("[*] Hubbub"))
}

@Test func theSummaryNamesWhatsMissing() throws {
    let game = try makeGame()
    #expect(PackageManagerApp.summary(for: game) == "Shipping 1 package next release.\nAdd a desktop environment in Packages first.")
    game.setIncluded(true, try #require(game.repository.package(id: "ucde")))
    #expect(PackageManagerApp.summary(for: game) == "Shipping 2 packages next release.")
}

@Test func thePackagesLayoutLoadsCleanly() throws {
    #expect(try Resources.loadScript(named: "packages").ignoredAttributes.isEmpty)
}
