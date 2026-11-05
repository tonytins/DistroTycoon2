import Foundation
import Hudini
import Raylib

@main
struct DistroTycoon {
    static func main() {
        let appearance = Appearance.standard
        let game: Game
        let createDistro: CreateDistroApp
        let terminal: TerminalApp
        do {
            game = try Game(repository: Resources.loadRepository())
            createDistro = try CreateDistroApp(appearance: appearance)
            terminal = try TerminalApp(game: game, appearance: appearance)
        } catch {
            failToStart(error.localizedDescription)
        }

        SetConfigFlags([.vsyncHint, .windowResizable])
        InitWindow(800, 600, "Distro Tycoon 2")
        guard IsWindowReady() else {
            failToStart("The game window couldn't be opened.")
        }
        SetWindowMinSize(640, 480)
        SetTargetFPS(60)
        // Hudini's panels use Escape to dismiss, so it can't also close the game.
        SetExitKey(.null)

        let desktop = Desktop(appearance: appearance)
        let distro = game.distro
        let menuBar = MenuBar(menus: [systemMenu(for: distro)], appearance: appearance)
        let notice = NoticePanel(theme: appearance.interface)
        let namingWindow = DesktopWindow(app: createDistro, appearance: appearance)
        let workspace = Workspace(
            dockItems: [
                Dock.Item(title: terminal.title, icon: .terminal, window: DesktopWindow(app: terminal, appearance: appearance)),
            ],
            appearance: appearance
        )
        workspace.open(namingWindow)
        var isQuitting = false
        var shownFocus: String?

        while !isQuitting && !WindowShouldClose() {
            if notice.isOpen {
                _ = notice.update()
            } else {
                let input = MenuInput.current()
                switch menuBar.update(input) {
                case .about:
                    notice.show(title: "About \(systemName(of: distro))", message: aboutMessage(for: distro))
                case .release:
                    notice.show(title: "Congrats!", message: game.release())
                case .quit:
                    isQuitting = true
                case .clearLog:
                    game.clearLog()
                case .closeWindow:
                    workspace.closeFocused()
                case nil:
                    break
                }
                if !menuBar.tookInput, case let .nameChosen(name)? = workspace.update(mouse: input.mouse, isPressed: input.isPressed) {
                    game.nameDistro(name)
                    workspace.close(namingWindow)
                    shownFocus = nil
                }
            }
            workspace.refresh()

            let focus = "\(distro.distroName)/\(workspace.focusedApp?.title ?? "")"
            if focus != shownFocus {
                shownFocus = focus
                menuBar.setMenus(menus(for: distro, focusedApp: workspace.focusedApp))
            }
            menuBar.status = distro.distroName.isEmpty ? "" : distro.versionLabel

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

        CloseWindow()
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
