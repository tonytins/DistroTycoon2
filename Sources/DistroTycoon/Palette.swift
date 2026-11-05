import Hudini
import Raylib

/// The game's colors, taken from the 16-color text mode palette it imitates.
enum Palette {
    static let blue = Color(r: 0, g: 0, b: 170, a: 255)
    static let darkBlue = Color(r: 0, g: 0, b: 128, a: 255)
    static let navy = Color(r: 0, g: 0, b: 85, a: 255)
    static let cyan = Color(r: 0, g: 170, b: 170, a: 255)
    static let lightGray = Color(r: 170, g: 170, b: 170, a: 255)
    static let black = Color(r: 0, g: 0, b: 0, a: 255)
    static let lightRed = Color(r: 255, g: 85, b: 85, a: 255)
    static let red = Color(r: 170, g: 0, b: 0, a: 255)
    static let yellow = Color(r: 255, g: 255, b: 85, a: 255)
    static let white = Color(r: 255, g: 255, b: 255, a: 255)

    /// Solid blue windows with white text, as a text mode program draws them.
    static let theme = InterfaceTheme(
        accent: yellow,
        inputBackground: navy,
        closeButton: lightRed,
        closeMark: red,
        overlay: Color(r: 0, g: 0, b: 0, a: 120),
        error: lightRed,
        panel: blue,
        border: white,
        text: white,
        secondaryText: lightGray,
        titleBar: darkBlue,
        selectedItem: cyan
    )
}
