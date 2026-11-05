import Hudini
import Raylib

/// The game's two loaded fonts. The host loads them after `InitWindow` and unloads them before `CloseWindow`.
struct Fonts {
    let interface: Font
    let monospaced: Font
}

/// The desktop's colors and fonts. Every color comes from one accent, so the player can pick any color.
struct Appearance {
    /// The accent the game starts with, a clear sky blue.
    static let standardAccent = Color(r: 30, g: 120, b: 220, a: 255)
    static let cornerRadius: Float = 8
    private static let fontSpacing: Float = 0
    private static let textSizes = InterfaceTheme.TextSizes(
        title: 15, label: 15, body: 15, button: 15, input: 16, tooltip: 13, problem: 12
    )

    /// The standard look with raylib's default font, for tests and anything drawn before fonts load.
    static var standard: Appearance {
        Appearance()
    }

    /// The color the player chose.
    let accent: Color
    let desktopTop: Color
    let desktopBottom: Color
    let barTop: Color
    let barBottom: Color
    let barEdge: Color
    let text: Color
    /// Fills a highlighted menu title or item.
    let highlight: Color
    /// Draws text on `highlight`.
    let highlightText: Color
    /// The look of Hudini's controls.
    let interface: InterfaceTheme
    /// The same look with the monospaced font, for apps such as the terminal.
    let console: InterfaceTheme

    private let fonts: Fonts?

    init(accent: Color = Appearance.standardAccent, fonts: Fonts? = nil) {
        let hsv = ColorToHSV(accent)
        let (hue, saturation) = (hsv.x, hsv.y)
        // Dark enough to read as text and outlines on the light windows, whatever the accent is.
        let strong = ColorFromHSV(hue, saturation, min(hsv.z, 0.7))
        let text = Color(r: 24, g: 28, b: 36, a: 255)

        self.accent = accent
        self.fonts = fonts
        desktopTop = ColorFromHSV(hue, saturation * 0.9, 0.55)
        desktopBottom = ColorFromHSV(hue, saturation * 0.3, 0.95)
        barTop = Color(r: 252, g: 252, b: 252, a: 245)
        barBottom = Color(r: 216, g: 220, b: 226, a: 245)
        barEdge = Color(r: 120, g: 126, b: 136, a: 255)
        self.text = text
        highlight = accent
        highlightText = Self.readableText(on: accent, dark: text)

        func theme(font: Font?) -> InterfaceTheme {
            InterfaceTheme(
                accent: strong,
                inputBackground: Color(r: 255, g: 255, b: 255, a: 255),
                closeButton: Color(r: 236, g: 95, b: 86, a: 255),
                closeMark: Color(r: 90, g: 20, b: 16, a: 255),
                overlay: Color(r: 0, g: 0, b: 0, a: 90),
                error: Color(r: 190, g: 40, b: 30, a: 255),
                panel: Color(r: 240, g: 243, b: 247, a: 235),
                border: Color(r: 120, g: 126, b: 136, a: 255),
                text: text,
                secondaryText: Color(r: 84, g: 90, b: 100, a: 255),
                titleBar: ColorFromHSV(hue, saturation * 0.08, 0.99),
                titleBarBottom: ColorFromHSV(hue, saturation * 0.3, 0.86),
                selectedItem: ColorFromHSV(hue, saturation * 0.4, 0.95),
                font: font,
                fontSpacing: Self.fontSpacing,
                textSizes: Self.textSizes,
                cornerRadius: Self.cornerRadius
            )
        }
        interface = theme(font: fonts?.interface)
        console = theme(font: fonts?.monospaced)
    }

    /// Draws text in the interface font, or the monospaced one.
    func drawText(_ text: String, x: Int, y: Int, size: Int, color: Color, monospaced: Bool = false) {
        guard let font = font(monospaced: monospaced) else {
            DrawText(text, x, y, size, color)
            return
        }
        DrawTextEx(font, text, Vector2(x: Float(x), y: Float(y)), Float(size), Self.fontSpacing, color)
    }

    /// Returns how wide `drawText` draws `text`.
    func textWidth(_ text: String, size: Int, monospaced: Bool = false) -> Int {
        guard let font = font(monospaced: monospaced) else {
            return MeasureText(text, size)
        }
        return Int(MeasureTextEx(font, text, Float(size), Self.fontSpacing).x.rounded(.up))
    }

    /// Fills `bounds` with the theme's rounded corners.
    func fillRounded(_ bounds: Rectangle, _ color: Color) {
        let shortest = min(bounds.width, bounds.height)
        guard shortest > 0 else {
            return
        }
        DrawRectangleRounded(bounds, min(1, Self.cornerRadius * 2 / shortest), 8, color)
    }

    /// Outlines `bounds` with the theme's rounded corners, drawing inside it.
    func outlineRounded(_ bounds: Rectangle, _ color: Color, thickness: Float = 1) {
        let inner = Rectangle(x: bounds.x + thickness, y: bounds.y + thickness, width: bounds.width - (thickness * 2), height: bounds.height - (thickness * 2))
        let shortest = min(inner.width, inner.height)
        guard shortest > 0 else {
            return
        }
        DrawRectangleRoundedLinesEx(inner, min(1, max(0, Self.cornerRadius - thickness) * 2 / shortest), 8, thickness, color)
    }

    /// Returns white or `dark`, whichever reads better on `background`.
    static func readableText(on background: Color, dark: Color) -> Color {
        let brightness = (0.299 * Float(background.r)) + (0.587 * Float(background.g)) + (0.114 * Float(background.b))
        return brightness > 160 ? dark : Color(r: 255, g: 255, b: 255, a: 255)
    }

    private func font(monospaced: Bool) -> Font? {
        monospaced ? fonts?.monospaced : fonts?.interface
    }
}
