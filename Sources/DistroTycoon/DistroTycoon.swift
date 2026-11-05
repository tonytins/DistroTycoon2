import Foundation
import Hudini
import Raylib

@main
struct DistroTycoon {
    private static let menus = [
        Menu(title: "File", hotkey: "F", items: [
            MenuItem(title: "About", hotkey: "A", command: .about),
            MenuItem(title: "Quit", hotkey: "Q", command: .quit),
        ]),
    ]

    static func main() {
        let createWindow: CreateDistroWindow
        do {
            createWindow = try CreateDistroWindow()
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

        let desktop = Desktop()
        let menuBar = MenuBar(menus: menus)
        let notice = NoticePanel(theme: Palette.theme)
        let distro = UserDistro()
        var openCreateWindow: CreateDistroWindow? = createWindow
        var isQuitting = false

        while !isQuitting && !WindowShouldClose() {
            if notice.isOpen {
                _ = notice.update()
            } else {
                switch menuBar.update(.current()) {
                case .about:
                    notice.show(title: "About Distro Tycoon 2", message: "Version \(GitVersion.version)")
                case .quit:
                    isQuitting = true
                case nil:
                    break
                }
                if !menuBar.tookInput, let name = openCreateWindow?.update() {
                    distro.nameDistro(name: name)
                    openCreateWindow = nil
                    notice.show(title: "Congrats!", message: distro.makeNewRelease())
                }
            }

            BeginDrawing()
            ClearBackground(Palette.blue)
            desktop.draw()
            openCreateWindow?.draw()
            menuBar.draw()
            if notice.isOpen {
                DrawRectangle(0, 0, Int(GetScreenWidth()), Int(GetScreenHeight()), Palette.theme.overlay)
                notice.draw()
            }
            EndDrawing()
        }

        desktop.unload()
        CloseWindow()
    }

    private static func failToStart(_ reason: String) -> Never {
        FileHandle.standardError.write(Data("Distro Tycoon 2 can't start: \(reason)\n".utf8))
        exit(1)
    }
}
