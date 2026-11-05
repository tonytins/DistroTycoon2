import Foundation
import Hudini
import Raylib

@main
struct DistroTycoon {
    // Fonts load at the size they're mostly drawn at, and raylib scales them for the rest.
    private static let fontLoadSize = 32

    static func main() {
        let game: Game
        do {
            game = try Game(repository: Resources.loadRepository())
        } catch {
            failToStart(error.localizedDescription)
        }

        SetConfigFlags([.vsyncHint, .windowResizable, .msaa4xHint])
        InitWindow(800, 600, "Distro Tycoon 2")
        guard IsWindowReady() else {
            failToStart("The game window couldn't be opened.")
        }
        SetWindowMinSize(640, 480)
        SetTargetFPS(60)
        // Hudini's panels use Escape to dismiss, so it can't also close the game.
        SetExitKey(.null)

        // Fonts and the views that draw with them need the window, so a failure here closes it first.
        let fonts: Fonts
        let createDistro: CreateDistroApp
        let terminal: TerminalApp
        let packageManager: PackageManagerApp
        let appearance: Appearance
        do {
            fonts = Fonts(
                interface: try Resources.loadFont(named: "OpenSans-Regular", size: fontLoadSize),
                monospaced: try Resources.loadFont(named: "FiraCode-Regular", size: fontLoadSize)
            )
            appearance = Appearance(fonts: fonts)
            createDistro = try CreateDistroApp(appearance: appearance)
            terminal = try TerminalApp(game: game, appearance: appearance)
            packageManager = try PackageManagerApp(game: game, appearance: appearance)
        } catch {
            CloseWindow()
            failToStart(error.localizedDescription)
        }

        let desktop = Desktop(appearance: appearance)
        let distro = game.distro
        let menuBar = MenuBar(menus: [systemMenu(for: distro)], appearance: appearance)
        let notice = NoticePanel(theme: appearance.interface)
        let namingWindow = DesktopWindow(app: createDistro, appearance: appearance)
        let workspace = Workspace(
            dockItems: [
                Dock.Item(title: packageManager.title, icon: .packages, window: DesktopWindow(app: packageManager, appearance: appearance)),
                Dock.Item(title: terminal.title, icon: .terminal, window: DesktopWindow(app: terminal, appearance: appearance)),
            ],
            appearance: appearance
        )
        workspace.open(namingWindow)
        var isQuitting = false
        var shownFocus: String?
        var clock = GameClock()
        var generator = SystemRandomNumberGenerator()

        while !isQuitting && !WindowShouldClose() {
            if notice.isOpen {
                _ = notice.update()
            } else {
                let input = MenuInput.current()
                menuBar.statusItems = speedItems(for: clock.speed, isRunning: !distro.distroName.isEmpty)
                switch menuBar.update(input) {
                case .about:
                    notice.show(title: "About \(systemName(of: distro))", message: aboutMessage(for: distro))
                case .release:
                    let problem = game.releaseProblem
                    notice.show(title: problem == nil ? "Congrats!" : "Not Yet", message: game.release())
                case .quit:
                    isQuitting = true
                case .clearLog:
                    game.clearLog()
                case .closeWindow:
                    workspace.closeFocused()
                case let .setSpeed(speed):
                    clock.speed = speed
                case nil:
                    break
                }
                if !menuBar.tookInput, case let .nameChosen(name)? = workspace.update(mouse: input.mouse, isPressed: input.isPressed) {
                    game.nameDistro(name)
                    workspace.close(namingWindow)
                    shownFocus = nil
                    clock.speed = .normal
                }
                // Days pass only while nothing modal is open, and only once the distro has a name.
                for _ in 0 ..< clock.advance(by: Double(GetFrameTime())) {
                    game.advanceDay(using: &generator)
                }
            }
            workspace.refresh()

            let focus = "\(distro.distroName)/\(workspace.focusedApp?.title ?? "")"
            if focus != shownFocus {
                shownFocus = focus
                menuBar.setMenus(menus(for: distro, focusedApp: workspace.focusedApp))
            }
            menuBar.status = distro.distroName.isEmpty ? "" : "Day \(game.day)    \(distro.versionLabel)"

            BeginDrawing()
            ClearBackground(appearance.desktopBottom)
            desktop.draw()
            workspace.draw()
            menuBar.draw()
            if notice.isOpen {
                DrawRectangle(0, 0, Int(GetScreenWidth()), Int(GetScreenHeight()), appearance.interface.overlay)
                notice.draw()
            }
            EndDrawing()
        }

        UnloadFont(fonts.interface)
        UnloadFont(fonts.monospaced)
        CloseWindow()
    }

    /// The speed buttons for the menu bar, which appear once the game is running.
    static func speedItems(for speed: GameSpeed, isRunning: Bool) -> [StatusItem] {
        guard isRunning else {
            return []
        }
        return [
            StatusItem(icon: .pause, command: .setSpeed(.paused), isSelected: speed == .paused),
            StatusItem(icon: .play, command: .setSpeed(.normal), isSelected: speed == .normal),
            StatusItem(icon: .fast, command: .setSpeed(.fast), isSelected: speed == .fast),
        ]
    }

    /// The system menu, followed by the focused app's menus.
    static func menus(for distro: UserDistro, focusedApp: (any DesktopApp)?) -> [Menu] {
        [systemMenu(for: distro)] + (focusedApp?.menus ?? [])
    }

    /// The menu that carries the player's distro, which is the desktop they are looking at.
    static func systemMenu(for distro: UserDistro) -> Menu {
        let name = systemName(of: distro)
        var items = [MenuItem(title: "About", hotkey: "A", command: .about)]
        if !distro.distroName.isEmpty {
            items.append(MenuItem(title: "Release", hotkey: "R", command: .release))
        }
        items.append(MenuItem(title: "Quit", hotkey: "Q", command: .quit))
        return Menu(title: name, hotkey: name.first(where: \.isLetter), items: items)
    }

    private static func systemName(of distro: UserDistro) -> String {
        distro.distroName.isEmpty ? "Distro Tycoon 2" : distro.distroName
    }

    private static func aboutMessage(for distro: UserDistro) -> String {
        let game = "Built with Distro Tycoon 2, version \(GitVersion.version)."
        return distro.distroName.isEmpty ? game : "\(distro.versionLabel). \(game)"
    }

    private static func failToStart(_ reason: String) -> Never {
        FileHandle.standardError.write(Data("Distro Tycoon 2 can't start: \(reason)\n".utf8))
        exit(1)
    }
}
