@testable import DistroTycoon
import Raylib
import Testing

private let dark = Color(r: 24, g: 28, b: 36, a: 255)

@Test(arguments: [
    (Color(r: 30, g: 120, b: 220, a: 255), true),
    (Color(r: 20, g: 20, b: 60, a: 255), true),
    (Color(r: 255, g: 240, b: 120, a: 255), false),
    (Color(r: 255, g: 255, b: 255, a: 255), false),
])
func highlightTextReadsOnAnyAccent(accent: Color, expectsWhite: Bool) {
    let text = Appearance(accent: accent).highlightText
    #expect((text.r == 255) == expectsWhite)
}

@Test(arguments: [
    Color(r: 255, g: 255, b: 0, a: 255),
    Color(r: 255, g: 255, b: 255, a: 255),
    Color(r: 0, g: 0, b: 0, a: 255),
    Color(r: 200, g: 40, b: 120, a: 255),
])
func accentOnWindowsStaysDarkEnoughToRead(accent: Color) {
    let strong = Appearance(accent: accent).interface.accent
    #expect(max(strong.r, strong.g, strong.b) <= 180)
}

@Test func anyAccentLeavesWindowsLightAndKeepsTheChoice() {
    let accent = Color(r: 200, g: 40, b: 120, a: 255)
    let appearance = Appearance(accent: accent)
    #expect(appearance.accent.r == accent.r && appearance.accent.g == accent.g && appearance.accent.b == accent.b)
    #expect(appearance.interface.panel.r > 200)
    #expect(appearance.text.r == dark.r)
}
