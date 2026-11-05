import Hudini
import Raylib

/// Shows the game's event log, laid out by `terminal.xml`.
final class TerminalApp: DesktopApp {
    private static let logList = "log"

    let title = "Terminal"
    let contentSize: Vector2
    let isClosable = true
    let menus = [
        Menu(title: "Terminal", hotkey: "T", items: [
            MenuItem(title: "Clear", hotkey: "C", command: .clearLog),
            MenuItem(title: "Close", hotkey: "O", command: .closeWindow),
        ]),
    ]

    private let game: Game
    private let view: UIScriptView
    private let list: TextList
    private var shownRevision = -1

    /// Reads the app's layout, and reports a document that can't be read or lacks a control the game needs.
    init(game: Game, appearance: Appearance = .standard) throws {
        let script = try Resources.loadScript(named: "terminal")
        view = UIScriptView(script: script, theme: appearance.console)
        guard let list = view.list(named: Self.logList) else {
            throw ResourceError.missingControl(document: "terminal")
        }
        self.list = list
        self.game = game
        contentSize = Vector2(x: script.window.size.width, y: script.window.size.height)
    }

    /// The lines on show.
    var lines: [String] {
        list.items
    }

    func refresh() {
        guard shownRevision != game.logRevision else {
            return
        }
        shownRevision = game.logRevision
        list.items = game.log
    }

    func update(at origin: Vector2) -> AppAction? {
        _ = view.update(at: origin)
        return nil
    }

    func draw(at origin: Vector2) {
        view.draw(at: origin)
    }
}
