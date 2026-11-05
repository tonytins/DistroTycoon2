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
    /// The menus the menu bar shows while this app has focus.
    var menus: [Menu] { get }

    /// Catches up with the game. This runs every frame the window is open, with or without focus.
    func refresh()
    /// Handles this frame's input with the content's corner at `origin`. Only the focused app gets this.
    func update(at origin: Vector2) -> AppAction?
    func draw(at origin: Vector2)
    /// Gives up keyboard focus, because another window took focus or this one closed.
    func resignFocus()
}

extension DesktopApp {
    var menus: [Menu] {
        []
    }

    func refresh() {}

    func resignFocus() {}
}

/// A movable window on the desktop, holding one app.
final class DesktopWindow: StackedWindow {
    /// What a window's input asks the desktop to act on.
    enum Update: Equatable {
        case close
        case action(AppAction)
    }

    // How much of a background window's color gives way to white, as early Aqua fades its background windows.
    private static let backgroundFade: Float = 0.35

    let app: any DesktopApp

    private let appearance: Appearance
    private let frame: WindowFrame
    private let size: Vector2

    init(app: any DesktopApp, appearance: Appearance) {
        self.app = app
        self.appearance = appearance
        frame = WindowFrame(title: app.title, theme: appearance.interface)
        frame.showsCloseButton = app.isClosable
        size = Vector2(x: app.contentSize.x, y: app.contentSize.y + Float(WindowFrame.titleHeight))
    }

    /// Handles this frame's input. Without `contentTakesInput`, the window can still start being
    /// dragged, but its close button and its app don't see the press.
    func update(contentTakesInput: Bool) -> Update? {
        let bounds = bounds
        if frame.followPointer(in: bounds) || !contentTakesInput {
            return nil
        }
        if frame.update(in: bounds) == .close {
            return .close
        }
        return app.update(at: Self.origin(in: bounds)).map(Update.action)
    }

    /// Draws the window. Draw the menu bar after it.
    func draw(isFocused: Bool) {
        let bounds = bounds
        frame.draw(in: bounds)
        app.draw(at: Self.origin(in: bounds))
        if !isFocused {
            appearance.fillRounded(bounds, ColorAlpha(Color(r: 255, g: 255, b: 255, a: 255), Self.backgroundFade))
        }
    }

    func contains(_ point: Vector2) -> Bool {
        CheckCollisionPointRec(point, bounds)
    }

    func resignFocus() {
        app.resignFocus()
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
