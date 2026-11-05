import Hudini
import Raylib

/// Something an app asks the game to act on.
enum AppAction: Equatable {
    case nameChosen(String)
}

/// The contents of a desktop window. The app draws inside the window, and `DesktopWindow` owns the frame.
protocol DesktopApp: AnyObject {
    var title: String { get }
    /// The size of the app's content, under the title bar.
    var contentSize: Vector2 { get }
    /// Whether the player can close the window.
    var isClosable: Bool { get }

    /// Handles this frame's input with the content's corner at `origin`.
    func update(at origin: Vector2) -> AppAction?
    func draw(at origin: Vector2)
}

/// A movable window on the desktop, holding one app.
final class DesktopWindow {
    private let app: any DesktopApp
    private let frame: WindowFrame
    private let size: Vector2

    init(app: any DesktopApp, appearance: Appearance) {
        self.app = app
        frame = WindowFrame(title: app.title, theme: appearance.interface)
        frame.showsCloseButton = app.isClosable
        size = Vector2(x: app.contentSize.x, y: app.contentSize.y + Float(WindowFrame.titleHeight))
    }

    /// Handles this frame's input and returns what the app asked for, if anything.
    func update() -> AppAction? {
        let bounds = bounds
        if frame.followPointer(in: bounds) {
            return nil
        }
        return app.update(at: Self.origin(in: bounds))
    }

    /// Draws the window. Draw the menu bar after it.
    func draw() {
        let bounds = bounds
        frame.draw(in: bounds)
        app.draw(at: Self.origin(in: bounds))
    }

    // Centered until moved. The frame only keeps itself on screen, so this also keeps its title
    // bar out from under the menu bar, where it couldn't be grabbed again.
    private var bounds: Rectangle {
        let start = Vector2(x: (Float(GetScreenWidth()) - size.x) / 2, y: (Float(GetScreenHeight()) - size.y) / 2)
        var bounds = frame.place(size: size, at: start)
        bounds.y = max(bounds.y, Float(MenuBar.height))
        return bounds
    }

    private static func origin(in bounds: Rectangle) -> Vector2 {
        let content = WindowFrame.content(in: bounds)
        return Vector2(x: content.x, y: content.y)
    }
}
