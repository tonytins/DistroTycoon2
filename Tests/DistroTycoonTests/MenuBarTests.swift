@testable import DistroTycoon
import Raylib
import Testing

// With 10 pixels a character, "File" spans x 0 to 60 on the bar, and its items span x 0 to 74.
private func makeBar() -> MenuBar {
    MenuBar(
        menus: [
            Menu(title: "File", hotkey: "F", items: [
                MenuItem(title: "About", hotkey: "A", command: .about),
                MenuItem(title: "Quit", hotkey: "Q", command: .quit),
            ]),
            Menu(title: "Help", hotkey: "H", items: []),
        ],
        measure: { $0.count * 10 }
    )
}

private let onFile = Vector2(x: 10, y: 10)
private let onHelp = Vector2(x: 70, y: 10)
private let onAbout = Vector2(x: 10, y: 40)
private let onQuit = Vector2(x: 10, y: 70)
private let onDesktop = Vector2(x: 400, y: 400)
private let onEmptyBar = Vector2(x: 400, y: 10)

private func press(_ point: Vector2) -> MenuInput {
    MenuInput(mouse: point, isPressed: true)
}

private func keys(_ keys: MenuInput.Key..., alt: Bool = false) -> MenuInput {
    MenuInput(isAltHeld: alt, keys: keys)
}

@Test func clickingTitleOpensThenCloses() {
    let bar = makeBar()
    #expect(bar.update(press(onFile)) == nil)
    #expect(bar.openMenu == 0)
    #expect(bar.tookInput)
    #expect(bar.update(press(onFile)) == nil)
    #expect(bar.openMenu == nil)
    #expect(bar.tookInput)
}

@Test func clickingItemChoosesItAndCloses() {
    let bar = makeBar()
    _ = bar.update(press(onFile))
    #expect(bar.update(press(onQuit)) == .quit)
    #expect(bar.openMenu == nil)
    #expect(bar.tookInput)
}

@Test func clickingOutsideClosesWithoutPassingTheClickOn() {
    let bar = makeBar()
    _ = bar.update(press(onFile))
    #expect(bar.update(press(onDesktop)) == nil)
    #expect(bar.openMenu == nil)
    #expect(bar.tookInput)
}

@Test func clickingDesktopWhileClosedIsLeftForTheDesktop() {
    let bar = makeBar()
    #expect(bar.update(press(onDesktop)) == nil)
    #expect(!bar.tookInput)
}

@Test func clickingEmptyBarIsTakenButOpensNothing() {
    let bar = makeBar()
    #expect(bar.update(press(onEmptyBar)) == nil)
    #expect(bar.openMenu == nil)
    #expect(bar.tookInput)
}

@Test func movingOverAnotherTitleSwitchesMenus() {
    let bar = makeBar()
    _ = bar.update(press(onFile))
    _ = bar.update(MenuInput(mouse: onHelp))
    #expect(bar.openMenu == 1)
}

@Test func movingOverTitlesWhileClosedOpensNothing() {
    let bar = makeBar()
    _ = bar.update(MenuInput(mouse: onDesktop))
    _ = bar.update(MenuInput(mouse: onFile))
    #expect(bar.openMenu == nil)
}

@Test func altAndHotkeyOpensWithFirstItemHighlighted() {
    let bar = makeBar()
    _ = bar.update(keys(.letter("F"), alt: true))
    #expect(bar.openMenu == 0)
    #expect(bar.highlightedItem == 0)
}

@Test func hotkeyWithoutAltDoesNothingWhileClosed() {
    let bar = makeBar()
    #expect(bar.update(keys(.letter("F"))) == nil)
    #expect(bar.update(keys(.letter("Q"))) == nil)
    #expect(bar.openMenu == nil)
    #expect(!bar.tookInput)
}

@Test func itemHotkeyChoosesWhileOpen() {
    let bar = makeBar()
    _ = bar.update(keys(.letter("F"), alt: true))
    #expect(bar.update(keys(.letter("Q"))) == .quit)
    #expect(bar.openMenu == nil)
}

@Test func arrowsWrapAndEnterChooses() {
    let bar = makeBar()
    _ = bar.update(keys(.letter("F"), alt: true))
    _ = bar.update(keys(.up))
    #expect(bar.highlightedItem == 1)
    _ = bar.update(keys(.down))
    #expect(bar.highlightedItem == 0)
    #expect(bar.update(keys(.enter)) == .about)
}

@Test func enterWithNothingHighlightedKeepsMenuOpen() {
    let bar = makeBar()
    _ = bar.update(press(onFile))
    #expect(bar.update(keys(.enter)) == nil)
    #expect(bar.openMenu == 0)
}

@Test func sideArrowsMoveBetweenMenusAndHandleAnEmptyOne() {
    let bar = makeBar()
    _ = bar.update(keys(.letter("F"), alt: true))
    _ = bar.update(keys(.left))
    #expect(bar.openMenu == 1)
    #expect(bar.highlightedItem == nil)
    _ = bar.update(keys(.down))
    #expect(bar.update(keys(.enter)) == nil)
    _ = bar.update(keys(.right))
    #expect(bar.openMenu == 0)
}

@Test func escapeCloses() {
    let bar = makeBar()
    _ = bar.update(keys(.letter("F"), alt: true))
    _ = bar.update(keys(.escape))
    #expect(bar.openMenu == nil)
    #expect(bar.tookInput)
}

@Test func restingPointerDoesNotOverrideArrowKeys() {
    let bar = makeBar()
    _ = bar.update(MenuInput(mouse: onAbout))
    _ = bar.update(MenuInput(mouse: onAbout, isAltHeld: true, keys: [.letter("F")]))
    _ = bar.update(MenuInput(mouse: onAbout, keys: [.down]))
    #expect(bar.highlightedItem == 1)
    _ = bar.update(MenuInput(mouse: onAbout))
    #expect(bar.highlightedItem == 1)
}
