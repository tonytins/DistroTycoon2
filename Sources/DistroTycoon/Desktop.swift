import Raylib

/// The glassy sky behind the game's windows, drawn from the appearance's colors.
struct Desktop {
    // Where each bubble sits and how big it is, as fractions of the window's size.
    private static let bubbles: [(x: Float, y: Float, radius: Float)] = [
        (0.08, 0.78, 0.07), (0.17, 0.90, 0.035), (0.30, 0.70, 0.02),
        (0.72, 0.84, 0.05), (0.84, 0.66, 0.09), (0.93, 0.90, 0.03),
    ]

    let appearance: Appearance

    /// Fills the window with the sky, its glow, and its bubbles.
    func draw() {
        let width = Float(GetScreenWidth())
        let height = Float(GetScreenHeight())
        DrawRectangleGradientV(0, 0, Int(width), Int(height), appearance.desktopTop, appearance.desktopBottom)

        let white = Color(r: 255, g: 255, b: 255, a: 255)
        let glow = Vector2(x: width * 0.5, y: height * 1.1)
        DrawCircleGradient(glow, width * 0.7, ColorAlpha(white, 0.55), ColorAlpha(white, 0))

        for bubble in Self.bubbles {
            let center = Vector2(x: width * bubble.x, y: height * bubble.y)
            let radius = width * bubble.radius
            DrawCircleGradient(center, radius, ColorAlpha(white, 0.04), ColorAlpha(white, 0.28))
            let shine = Vector2(x: center.x - (radius * 0.35), y: center.y - (radius * 0.4))
            DrawCircleGradient(shine, radius * 0.4, ColorAlpha(white, 0.6), ColorAlpha(white, 0))
        }
    }
}
