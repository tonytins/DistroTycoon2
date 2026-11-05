import Hudini
import Raylib

/// The desktop's colors, all worked out from one accent color so the player can pick any color.
struct Appearance: Sendable {
    /// The accent the game starts with, a clear sky blue.
    static let standardAccent = Color(r: 30, g: 120, b: 220, a: 255)
    static let standard = Appearance()

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
    /// The colors for Hudini's controls.
    let interface: InterfaceTheme

    init(accent: Color = Appearance.standardAccent) {
        let hsv = ColorToHSV(accent)
        let (hue, saturation) = (hsv.x, hsv.y)
        // Dark enough to read as text and outlines on the light windows, whatever the accent is.
        let strong = ColorFromHSV(hue, saturation, min(hsv.z, 0.7))
        let text = Color(r: 24, g: 28, b: 36, a: 255)

        self.accent = accent
        desktopTop = ColorFromHSV(hue, saturation * 0.9, 0.55)
        desktopBottom = ColorFromHSV(hue, saturation * 0.3, 0.95)
        barTop = Color(r: 252, g: 252, b: 252, a: 245)
        barBottom = Color(r: 216, g: 220, b: 226, a: 245)
        barEdge = Color(r: 120, g: 126, b: 136, a: 255)
        self.text = text
        highlight = accent
        highlightText = Self.readableText(on: accent, dark: text)
        interface = InterfaceTheme(
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
            titleBar: ColorFromHSV(hue, saturation * 0.2, 0.92),
            selectedItem: ColorFromHSV(hue, saturation * 0.4, 0.95)
        )
    }

    /// Returns white or `dark`, whichever reads better on `background`.
    static func readableText(on background: Color, dark: Color) -> Color {
        let brightness = (0.299 * Float(background.r)) + (0.587 * Float(background.g)) + (0.114 * Float(background.b))
        return brightness > 160 ? dark : Color(r: 255, g: 255, b: 255, a: 255)
    }
}
