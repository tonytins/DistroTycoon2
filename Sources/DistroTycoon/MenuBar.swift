import Hudini
import Raylib

/// Something the player can ask for from the menu bar.
enum MenuCommand: Equatable {
    case about
    case release
    case quit
    case clearLog
    case closeWindow
    case setSpeed(GameSpeed)
    case toggleHubbub
}

/// A button at the right end of the menu bar.
struct StatusItem: Equatable {
    enum Icon: Equatable {
        case hubbub, pause, play, fast
    }

    let icon: Icon
    let command: MenuCommand
    let isSelected: Bool
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

    private static let fontSize = 16
    private static let textTop = 6
    private static let titlePadding = 10
    private static let itemHeight = 28
    private static let itemPadding = 12
    private static let statusPadding = 12
    private static let itemWidth = 26
    private static let itemGap = 2

    private let appearance: Appearance
    private let measure: (String) -> Int

    private var menus: [Menu]
    private var lastMouse: Vector2?

    /// Text at the bar's right end, left of its items. It's left out when the window is too narrow.
    var status = ""
    /// Buttons at the bar's right end, from left to right.
    var statusItems: [StatusItem] = []

    /// The open menu's index, or `nil` when every menu is closed.
    private(set) var openMenu: Int?

    /// The highlighted item in the open menu.
    private(set) var highlightedItem: Int?

    /// Whether the last update used the pointer or keyboard, so that nothing under the bar should.
    private(set) var tookInput = false

    /// Creates a bar. `measure` gives a label's width in pixels, by default in the appearance's font.
    init(menus: [Menu], appearance: Appearance = .standard, measure: ((String) -> Int)? = nil) {
        self.menus = menus
        self.appearance = appearance
        self.measure = measure ?? { appearance.textWidth($0, size: MenuBar.fontSize) }
    }

    /// Replaces the menus, such as when another app takes focus, and closes any open one.
    func setMenus(_ menus: [Menu]) {
        self.menus = menus
        close()
    }

    /// Handles a frame's input and returns the command the player chose, if any. `barWidth` is how
    /// wide the bar is, which places its status items.
    func update(_ input: MenuInput, barWidth: Int? = nil) -> MenuCommand? {
        let wasOpen = openMenu != nil
        if input.isPressed, openMenu == nil, let item = statusItemIndex(at: input.mouse, barWidth: barWidth ?? Int(GetScreenWidth())) {
            lastMouse = input.mouse
            tookInput = true
            return statusItems[item].command
        }
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
                y: Self.textTop,
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

    private func statusItemBounds(_ index: Int, barWidth: Int) -> Rectangle {
        let fromRight = statusItems.count - index
        let x = barWidth - Self.itemGap - (fromRight * (Self.itemWidth + Self.itemGap))
        return Rectangle(x: Float(x), y: 2, width: Float(Self.itemWidth), height: Float(Self.height - 4))
    }

    private func statusItemIndex(at point: Vector2, barWidth: Int) -> Int? {
        statusItems.indices.first { CheckCollisionPointRec(point, statusItemBounds($0, barWidth: barWidth)) }
    }

    private func drawStatus(barWidth: Int) {
        let mouse = GetMousePosition()
        for (index, item) in statusItems.enumerated() {
            let bounds = statusItemBounds(index, barWidth: barWidth)
            if item.isSelected || CheckCollisionPointRec(mouse, bounds) {
                appearance.fillRounded(bounds, item.isSelected ? appearance.highlight : appearance.barBottom)
            }
            drawIcon(item.icon, in: bounds, color: item.isSelected ? appearance.highlightText : appearance.text)
        }
        let itemsStart = statusItems.isEmpty ? barWidth : Int(statusItemBounds(0, barWidth: barWidth).x)
        let menusEnd = menus.indices.last.map { Int(titleBounds($0).x + titleBounds($0).width) } ?? 0
        let x = itemsStart - measure(status) - Self.statusPadding
        guard !status.isEmpty, x > menusEnd else {
            return
        }
        appearance.drawText(status, x: x, y: Self.textTop, size: Self.fontSize, color: appearance.text)
    }

    // The bundled fonts hold only printable ASCII, so the speed symbols are drawn as shapes.
    private func drawIcon(_ icon: StatusItem.Icon, in bounds: Rectangle, color: Color) {
        let center = Vector2(x: bounds.x + (bounds.width / 2), y: bounds.y + (bounds.height / 2))
        func triangle(at x: Float) {
            DrawTriangle(Vector2(x: x, y: center.y - 6), Vector2(x: x, y: center.y + 6), Vector2(x: x + 9, y: center.y), color)
        }
        switch icon {
        case .hubbub:
            // A speech bubble, for the chatter of a busy project.
            let bubble = Rectangle(x: center.x - 9, y: center.y - 7, width: 18, height: 12)
            appearance.fillRounded(bubble, color)
            DrawTriangle(Vector2(x: center.x - 4, y: bubble.y + bubble.height - 1), Vector2(x: center.x - 6, y: center.y + 9), Vector2(x: center.x + 1, y: bubble.y + bubble.height - 1), color)
            let dots = color.r > 128 ? appearance.highlight : appearance.barTop
            for offset: Float in [-5, 0, 5] {
                DrawCircleV(Vector2(x: center.x + offset, y: center.y - 1), 1.5, dots)
            }
        case .pause:
            DrawRectangleRec(Rectangle(x: center.x - 5, y: center.y - 6, width: 3, height: 12), color)
            DrawRectangleRec(Rectangle(x: center.x + 2, y: center.y - 6, width: 3, height: 12), color)
        case .play:
            triangle(at: center.x - 4)
        case .fast:
            triangle(at: center.x - 9)
            triangle(at: center.x)
        }
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
                y: Int(bounds.y) + Self.textTop,
                color: isHighlighted ? appearance.highlightText : appearance.text,
                isBold: false
            )
        }
        DrawRectangleLinesEx(list, 1.0, appearance.barEdge)
    }

    // Underlines the hotkey's letter. Bold is the font drawn twice, a pixel apart, so only one font needs loading.
    private func drawLabel(_ text: String, hotkey: Character?, x: Int, y: Int, color: Color, isBold: Bool) {
        appearance.drawText(text, x: x, y: y, size: Self.fontSize, color: color)
        if isBold {
            appearance.drawText(text, x: x + 1, y: y, size: Self.fontSize, color: color)
        }
        guard let hotkey, let letter = text.firstIndex(where: { Self.matches($0, hotkey) }) else {
            return
        }
        let start = measure(String(text[..<letter]))
        let width = measure(String(text[letter]))
        DrawRectangle(x + start, y + Self.fontSize + 1, width, 1, color)
    }

    private static func isOnBar(_ point: Vector2) -> Bool {
        point.y >= 0 && point.y < Float(height)
    }

    private static func matches(_ first: Character, _ second: Character) -> Bool {
        first.lowercased() == second.lowercased()
    }
}
