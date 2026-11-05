import Hudini
import Raylib

/// The row of app buttons centered along the bottom of the desktop.
struct Dock {
    enum Icon {
        case terminal
        case packages
    }

    /// An app the dock can open.
    struct Item {
        let title: String
        let icon: Icon
        let window: DesktopWindow
    }

    private static let bottomGap: Float = 8
    private static let labelSize = 14
    private static let iconTextSize = 18
    private static let labelPadding = 6

    let items: [Item]
    let appearance: Appearance

    /// The area to give `IconToolbar` so that its bottom-left row ends up centered above the gap.
    static func area(itemCount: Int, screen: Vector2) -> Rectangle {
        let width = IconToolbar.bounds(itemCount: itemCount, in: Rectangle(), inset: 0).width
        return Rectangle(x: (screen.x - width) / 2, y: 0, width: width, height: screen.y - bottomGap)
    }

    /// Whether `point` is on the dock's background or one of its buttons.
    static func contains(_ point: Vector2, itemCount: Int, screen: Vector2) -> Bool {
        let bar = IconToolbar.bounds(itemCount: itemCount, in: area(itemCount: itemCount, screen: screen), inset: 0)
        return CheckCollisionPointRec(point, bar)
    }

    /// Returns the index of the button under `point`, if any.
    static func itemIndex(at point: Vector2, itemCount: Int, screen: Vector2) -> Int? {
        IconToolbar.buttonIndex(at: point, itemCount: itemCount, in: area(itemCount: itemCount, screen: screen), inset: 0)
    }

    /// Draws the dock. `isOpen` says which apps get a mark, and `focused` is highlighted.
    func draw(focused: Int?, isOpen: (Int) -> Bool) {
        let screen = Vector2(x: Float(GetScreenWidth()), y: Float(GetScreenHeight()))
        let mouse = GetMousePosition()
        let area = Self.area(itemCount: items.count, screen: screen)
        IconToolbar.draw(
            itemCount: items.count,
            selectedIndex: focused,
            mousePosition: mouse,
            in: area,
            inset: 0,
            theme: appearance.interface
        ) { index, bounds, _ in
            drawIcon(items[index].icon, in: bounds)
            if isOpen(index) {
                DrawCircle(Int(bounds.x + (bounds.width / 2)), Int(bounds.y + bounds.height + 3), 2, appearance.text)
            }
        }
        if let hovered = Self.itemIndex(at: mouse, itemCount: items.count, screen: screen) {
            drawLabel(items[hovered].title, over: IconToolbar.buttonBounds(at: hovered, itemCount: items.count, in: area, inset: 0))
        }
    }

    private func drawIcon(_ icon: Icon, in bounds: Rectangle) {
        let face = Rectangle(x: bounds.x + 4, y: bounds.y + 4, width: bounds.width - 8, height: bounds.height - 8)
        switch icon {
        case .terminal:
            appearance.fillRounded(face, Color(r: 16, g: 20, b: 24, a: 255))
            appearance.drawText(">_", x: Int(face.x) + 5, y: Int(face.y) + 7, size: Self.iconTextSize, color: Color(r: 200, g: 240, b: 208, a: 255), monospaced: true)
        case .packages:
            // A cardboard box with its tape.
            let box = Rectangle(x: face.x + 3, y: face.y + 7, width: face.width - 6, height: face.height - 10)
            appearance.fillRounded(box, Color(r: 196, g: 150, b: 96, a: 255))
            DrawRectangleRec(Rectangle(x: box.x, y: box.y, width: box.width, height: 7), Color(r: 222, g: 182, b: 128, a: 255))
            DrawRectangleRec(Rectangle(x: box.x + (box.width / 2) - 3, y: box.y, width: 6, height: box.height), Color(r: 236, g: 222, b: 190, a: 255))
        }
    }

    private func drawLabel(_ title: String, over button: Rectangle?) {
        guard let button else {
            return
        }
        let width = appearance.textWidth(title, size: Self.labelSize) + (Self.labelPadding * 2)
        let pill = Rectangle(
            x: button.x + ((button.width - Float(width)) / 2),
            y: button.y - Float(Self.labelSize) - 24,
            width: Float(width),
            height: Float(Self.labelSize + 8)
        )
        appearance.fillRounded(pill, appearance.interface.panel)
        appearance.drawText(title, x: Int(pill.x) + Self.labelPadding, y: Int(pill.y) + 3, size: Self.labelSize, color: appearance.text)
    }
}
