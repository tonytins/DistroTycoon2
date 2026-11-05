import Hudini
import Raylib

/// The row of app buttons centered along the bottom of the desktop.
struct Dock {
    enum Icon {
        case terminal
    }

    /// An app the dock can open.
    struct Item {
        let title: String
        let icon: Icon
        let window: DesktopWindow
    }

    private static let bottomGap: Float = 8
    private static let labelSize = 20
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
            DrawRectangleRounded(face, 0.2, 6, Color(r: 16, g: 20, b: 24, a: 255))
            DrawText(">_", Int(face.x) + 5, Int(face.y) + 8, Self.labelSize, Color(r: 200, g: 240, b: 208, a: 255))
        }
    }

    private func drawLabel(_ title: String, over button: Rectangle?) {
        guard let button else {
            return
        }
        let width = MeasureText(title, Self.labelSize) + (Self.labelPadding * 2)
        let pill = Rectangle(
            x: button.x + ((button.width - Float(width)) / 2),
            y: button.y - Float(Self.labelSize) - 22,
            width: Float(width),
            height: Float(Self.labelSize + 6)
        )
        DrawRectangleRounded(pill, 0.5, 6, appearance.interface.panel)
        DrawText(title, Int(pill.x) + Self.labelPadding, Int(pill.y) + 3, Self.labelSize, appearance.text)
    }
}
