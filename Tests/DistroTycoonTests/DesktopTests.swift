@testable import DistroTycoon
import Raylib
import Testing

private let screen = Vector2(x: 800, y: 600)

@Test(arguments: [1, 2, 5])
func theDockIsCenteredAlongTheBottom(itemCount: Int) {
    let area = Dock.area(itemCount: itemCount, screen: screen)
    #expect(area.x + (area.width / 2) == 400)
    #expect(area.height == 592)
}

@Test func theDockFindsItsButtonsAndNothingElse() {
    #expect(Dock.itemIndex(at: Vector2(x: 400, y: 565), itemCount: 1, screen: screen) == 0)
    #expect(Dock.contains(Vector2(x: 400, y: 565), itemCount: 1, screen: screen))
    #expect(Dock.itemIndex(at: Vector2(x: 400, y: 300), itemCount: 1, screen: screen) == nil)
    #expect(!Dock.contains(Vector2(x: 400, y: 300), itemCount: 1, screen: screen))
    #expect(!Dock.contains(Vector2(x: 100, y: 565), itemCount: 1, screen: screen))
}

@Test func theMenusAreTheSystemMenuAndTheFocusedApps() throws {
    let game = try Game(repository: Resources.loadRepository())
    game.distro.nameDistro(name: "Tuxedo")
    #expect(DistroTycoon.menus(for: game.distro, focusedApp: nil).map(\.title) == ["Tuxedo"])
    let terminal = try TerminalApp(game: game)
    #expect(DistroTycoon.menus(for: game.distro, focusedApp: terminal).map(\.title) == ["Tuxedo", "Terminal"])
}

@Test func theTerminalShowsTheLogOnceItCatchesUp() throws {
    let game = try Game(repository: Resources.loadRepository())
    let terminal = try TerminalApp(game: game)
    game.nameDistro("Tuxedo")
    #expect(terminal.lines.isEmpty)
    terminal.refresh()
    #expect(terminal.lines == game.log)
    game.clearLog()
    terminal.refresh()
    #expect(terminal.lines.isEmpty)
}

@Test func theTerminalLayoutLoadsCleanly() throws {
    #expect(try Resources.loadScript(named: "terminal").ignoredAttributes.isEmpty)
}
