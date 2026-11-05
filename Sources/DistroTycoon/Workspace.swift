import Raylib

/// The desktop's windows and dock, and which of them gets each frame's input.
final class Workspace {
    private let stack = WindowStack<DesktopWindow>()
    private let dock: Dock

    init(dockItems: [Dock.Item], appearance: Appearance) {
        dock = Dock(items: dockItems, appearance: appearance)
    }

    /// The app in the window with focus.
    var focusedApp: (any DesktopApp)? {
        stack.front?.app
    }

    func open(_ window: DesktopWindow) {
        stack.focus(window)
    }

    func close(_ window: DesktopWindow) {
        stack.close(window)
    }

    func closeFocused() {
        if let front = stack.front {
            stack.close(front)
        }
    }

    /// Handles this frame's pointer and returns what the focused app asked for, if anything.
    ///
    /// The dock comes first because it draws on top. A press that brings a window forward can still
    /// start a drag on its title bar, but goes no further into the window.
    func update(mouse: Vector2, isPressed: Bool) -> AppAction? {
        let screen = Vector2(x: Float(GetScreenWidth()), y: Float(GetScreenHeight()))
        if isPressed, Dock.contains(mouse, itemCount: dock.items.count, screen: screen) {
            if let index = Dock.itemIndex(at: mouse, itemCount: dock.items.count, screen: screen) {
                stack.focus(dock.items[index].window)
            }
            return nil
        }
        let onlyTookFocus = isPressed && stack.press(at: mouse)
        guard let front = stack.front else {
            return nil
        }
        switch front.update(contentTakesInput: !onlyTookFocus) {
        case .close:
            stack.close(front)
            return nil
        case let .action(action):
            return action
        case nil:
            return nil
        }
    }

    /// Lets every open app catch up with the game, even those not taking input.
    func refresh() {
        for window in stack.windows {
            window.app.refresh()
        }
    }

    /// Draws the windows from back to front, then the dock. Draw the menu bar after this.
    func draw() {
        for window in stack.windows {
            window.draw(isFocused: window === stack.front)
        }
        let items = dock.items
        dock.draw(
            focused: items.firstIndex { $0.window === stack.front },
            isOpen: { stack.isOpen(items[$0].window) }
        )
    }
}
