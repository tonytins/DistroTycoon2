import Hudini
import Raylib

@main
struct DistroTycoon {
    static func main() {
        SetConfigFlags([.vsyncHint, .windowResizable])
        InitWindow(800, 600, "Distro Tycoon 2")
        SetWindowMinSize(640, 480)
        SetTargetFPS(60)
        // Hudini's panels use Escape to dismiss, so it can't also close the game.
        SetExitKey(.null)

        let desktop = Desktop()

        while !WindowShouldClose() {
            BeginDrawing()
            ClearBackground(Palette.blue)
            desktop.draw()
            EndDrawing()
        }

        desktop.unload()
        CloseWindow()
    }
}
