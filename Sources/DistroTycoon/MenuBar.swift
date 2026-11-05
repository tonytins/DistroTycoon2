import Hudini
import Raylib

/// Something the player can ask for from the menu bar.
enum MenuCommand: Equatable {
    case about
    case release
    case quit
}

/// A choice in a drop-down menu. `hotkey` is the letter that picks it while the menu is open.
struct MenuItem {
    let title: String
    let hotkey: Character
    let command: MenuCommand
}

/// A drop-down menu. Alt and `hotkey` open it from the keyboard, when it has one.
struct Menu {
    let title: String
    let hotkey: Character?
    let items: [MenuItem]
}

/// One frame of the input a menu bar responds to.
struct MenuInput {
    enum Key: Equatable {
        case up, down, left, right, enter, escape
        case letter(Character)
    }

    var mouse: Vector2 = .zero
    var isPressed = false
    var isAltHeld = false
    var keys: [Key] = []

    /// Reads this frame's input from raylib. This takes the frame's queue from `GetKeyPressed`.
    static func current() -> MenuInput {
        var input = MenuInput(
            mouse: GetMousePosition(),
            isPressed: IsMouseButtonPressed(.left),
            isAltHeld: IsKeyDown(.leftAlt) || IsKeyDown(.rightAlt)
        )
        var code = Int(GetKeyPressed())
        while code != 0 {
            if let key = Key(keyCode: code) {
                input.keys.append(key)
            }
            code = Int(GetKeyPressed())
        }
        return input
    }
}

extension MenuInput.Key {
    private static let named: [(KeyboardKey, MenuInput.Key)] = [
        (.up, .up), (.down, .down), (.left, .left), (.right, .right),
        (.enter, .enter), (.kpEnter, .enter), (.escape, .escape),
    ]

    fileprivate init?(keyCode: Int) {
        if let match = Self.named.first(where: { Int($0.0.rawValue) == keyCode }) {
            self = match.1
        } else if let letter = Unicode.Scalar(UInt32(clamping: keyCode)), ("A"..."Z").contains(letter) {
            self = .letter(Character(letter))
        } else {
            return nil
        }
    }
}

/// The global menu along the top of the window. Its first menu is the system menu, drawn in bold.
final class MenuBar {
    static let height = 28

    private static let fontSize = 20
    private static let titlePadding = 10
    private static let itemHeight = 28
    private static let itemPadding = 12
    private static let statusPadding = 12

    private let appearance: Appearance
    private let measure: (String) -> Int

    private var menus: [Menu]
    private var lastMouse: Vector2?

    /// Text at the bar's right end, left out when the window is too narrow to fit it.
    var status = ""

    /// The open menu's index, or `nil` when every menu is closed.
    private(set) var openMenu: Int?

    /// The highlighted item in the open menu.
    private(set) var highlightedItem: Int?

    /// Whether the last update used the pointer or keyboard, so that nothing under the bar should.
    private(set) var tookInput = false

    /// Creates a bar. `measure` gives a label's width in pixels, by default at the bar's font size.
    init(
        menus: [Menu],
        appearance: Appearance = .standard,
        measure: @escaping (String) -> Int = { MeasureText($0, MenuBar.fontSize) }
    ) {
        self.menus = menus
        self.appearance = appearance
        self.measure = measure
    }

    /// Replaces the menus, such as when another app takes focus, and closes any open one.
    func setMenus(_ menus: [Menu]) {
        self.menus = menus
        close()
    }

    /// Handles a frame's input and returns the command the player chose, if any.
    func update(_ input: MenuInput) -> MenuCommand? {
        let wasOpen = openMenu != nil
        var command = handleKeys(input)
        if command == nil {
            followPointer(to: input.mouse)
            if input.isPressed {
                command = handlePress(at: input.mouse)
            }
        }
        lastMouse = input.mouse
        tookInput = wasOpen || openMenu != nil || (input.isPressed && Self.isOnBar(input.mouse))
        return command
    }

    /// Draws the bar. Draw it after the desktop's windows so that an open menu sits on top of them.
    func draw() {
        let width = Int(GetScreenWidth())
        DrawRectangleGradientV(0, 0, width, Self.height, appearance.barTop, appearance.barBottom)
        DrawLine(0, Self.height, width, Self.height, appearance.barEdge)
        for index in menus.indices {
            let bounds = titleBounds(index)
            let isOpen = openMenu == index
            if isOpen {
                DrawRectangleRec(bounds, appearance.highlight)
            }
            drawLabel(
                menus[index].title,
                hotkey: menus[index].hotkey,
                x: Int(bounds.x) + Self.titlePadding,
                y: 4,
                color: isOpen ? appearance.highlightText : appearance.text,
                isBold: index == 0
            )
        }
        drawStatus(barWidth: width)
        if let openMenu {
            drawDropDown(openMenu)
        }
    }

    private func handleKeys(_ input: MenuInput) -> MenuCommand? {
        for key in input.keys {
            if input.isAltHeld, case let .letter(letter) = key, let index = menus.firstIndex(where: { $0.hotkey.map { Self.matches($0, letter) } ?? false }) {
                open(index, highlighting: 0)
            } else if let openMenu, let command = handleKey(key, in: openMenu) {
                return command
            }
        }
        return nil
    }

    private func handleKey(_ key: MenuInput.Key, in menu: Int) -> MenuCommand? {
        let items = menus[menu].items
        switch key {
        case .escape:
            close()
        case .up:
            moveHighlight(by: -1, count: items.count)
        case .down:
            moveHighlight(by: 1, count: items.count)
        case .left:
            open((menu + menus.count - 1) % menus.count, highlighting: 0)
        case .right:
            open((menu + 1) % menus.count, highlighting: 0)
        case .enter:
            if let highlightedItem {
                return choose(items[highlightedItem])
            }
        case let .letter(letter):
            if let item = items.first(where: { Self.matches($0.hotkey, letter) }) {
                return choose(item)
            }
        }
        return nil
    }

    // Only a moved pointer changes the highlight, so that a resting pointer doesn't fight the arrow keys.
    private func followPointer(to mouse: Vector2) {
        guard let openMenu, let lastMouse, lastMouse.x != mouse.x || lastMouse.y != mouse.y else {
            return
        }
        if let title = menus.indices.first(where: { CheckCollisionPointRec(mouse, titleBounds($0)) }), title != openMenu {
            open(title, highlighting: nil)
        } else if let item = itemIndex(at: mouse, in: openMenu) {
            highlightedItem = item
        } else {
            highlightedItem = nil
        }
    }

    private func handlePress(at mouse: Vector2) -> MenuCommand? {
        if let title = menus.indices.first(where: { CheckCollisionPointRec(mouse, titleBounds($0)) }) {
            if openMenu == title {
                close()
            } else {
                open(title, highlighting: nil)
            }
            return nil
        }
        guard let openMenu else {
            return nil
        }
        if let item = itemIndex(at: mouse, in: openMenu) {
            return choose(menus[openMenu].items[item])
        }
        close()
        return nil
    }

    private func open(_ menu: Int, highlighting item: Int?) {
        openMenu = menu
        highlightedItem = menus[menu].items.isEmpty ? nil : item
    }

    private func close() {
        openMenu = nil
        highlightedItem = nil
    }

    private func choose(_ item: MenuItem) -> MenuCommand {
        close()
        return item.command
    }

    private func moveHighlight(by step: Int, count: Int) {
        guard count > 0 else {
            return
        }
        guard let highlightedItem else {
            self.highlightedItem = step > 0 ? 0 : count - 1
            return
        }
        self.highlightedItem = (highlightedItem + step + count) % count
    }

    private func titleBounds(_ index: Int) -> Rectangle {
        var x = 0
        for menu in menus[..<index] {
            x += measure(menu.title) + (Self.titlePadding * 2)
        }
        return Rectangle(x: Float(x), y: 0, width: Float(measure(menus[index].title) + (Self.titlePadding * 2)), height: Float(Self.height))
    }

    private func dropDownBounds(_ menu: Int) -> Rectangle {
        let items = menus[menu].items
        let widest = items.map { measure($0.title) }.max() ?? 0
        return Rectangle(
            x: titleBounds(menu).x,
            y: Float(Self.height),
            width: Float(widest + (Self.itemPadding * 2)),
            height: Float(items.count * Self.itemHeight)
        )
    }

    private func itemBounds(_ item: Int, in menu: Int) -> Rectangle {
        let list = dropDownBounds(menu)
        return Rectangle(x: list.x, y: list.y + Float(item * Self.itemHeight), width: list.width, height: Float(Self.itemHeight))
    }

    private func itemIndex(at point: Vector2, in menu: Int) -> Int? {
        menus[menu].items.indices.first { CheckCollisionPointRec(point, itemBounds($0, in: menu)) }
    }

    private func drawStatus(barWidth: Int) {
        let menusEnd = menus.indices.last.map { Int(titleBounds($0).x + titleBounds($0).width) } ?? 0
        let x = barWidth - measure(status) - Self.statusPadding
        guard !status.isEmpty, x > menusEnd else {
            return
        }
        DrawText(status, x, 4, Self.fontSize, appearance.text)
    }

    private func drawDropDown(_ menu: Int) {
        let list = dropDownBounds(menu)
        DrawRectangleRec(list, appearance.barTop)
        for (index, item) in menus[menu].items.enumerated() {
            let bounds = itemBounds(index, in: menu)
            let isHighlighted = highlightedItem == index
            if isHighlighted {
                DrawRectangleRec(bounds, appearance.highlight)
            }
            drawLabel(
                item.title,
                hotkey: item.hotkey,
                x: Int(bounds.x) + Self.itemPadding,
                y: Int(bounds.y) + 4,
                color: isHighlighted ? appearance.highlightText : appearance.text,
                isBold: false
            )
        }
        DrawRectangleLinesEx(list, 1.0, appearance.barEdge)
    }

    // Underlines the hotkey's letter. The default font has no bold, so bold is drawn twice, a pixel apart.
    private func drawLabel(_ text: String, hotkey: Character?, x: Int, y: Int, color: Color, isBold: Bool) {
        DrawText(text, x, y, Self.fontSize, color)
        if isBold {
            DrawText(text, x + 1, y, Self.fontSize, color)
        }
        guard let hotkey, let letter = text.firstIndex(where: { Self.matches($0, hotkey) }) else {
            return
        }
        let start = measure(String(text[..<letter]))
        let width = measure(String(text[letter]))
        DrawRectangle(x + start, y + Self.fontSize, width, 2, color)
    }

    private static func isOnBar(_ point: Vector2) -> Bool {
        point.y >= 0 && point.y < Float(height)
    }

    private static func matches(_ first: Character, _ second: Character) -> Bool {
        first.lowercased() == second.lowercased()
    }
}
