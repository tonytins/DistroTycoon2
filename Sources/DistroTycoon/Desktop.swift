import Raylib

/// The hatched blue background behind the game's windows.
final class Desktop {
    private static let tileSize = 4
    private static let checkSize = 2

    private let pattern: Texture2D

    /// Creates the pattern's texture. Call this after `InitWindow`.
    init() {
        let image = GenImageChecked(Self.tileSize, Self.tileSize, Self.checkSize, Self.checkSize, Palette.blue, Palette.darkBlue)
        pattern = LoadTextureFromImage(image)
        UnloadImage(image)
        SetTextureWrap(pattern, .repeat)
    }

    /// Fills the window with the pattern, or leaves the background flat if its texture failed to load.
    func draw() {
        guard IsTextureValid(pattern) else {
            return
        }
        let source = Rectangle(x: 0, y: 0, width: Float(GetScreenWidth()), height: Float(GetScreenHeight()))
        DrawTextureRec(pattern, source, .zero, .white)
    }

    /// Releases the pattern's texture. Call this before `CloseWindow`.
    func unload() {
        UnloadTexture(pattern)
    }
}
