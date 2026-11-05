import Raylib

/// What a window stack needs from its windows.
protocol StackedWindow: AnyObject {
    func contains(_ point: Vector2) -> Bool
    /// Called when another window takes focus.
    func resignFocus()
}

/// The open windows from back to front. The front window has focus.
final class WindowStack<Window: StackedWindow> {
    private(set) var windows: [Window] = []

    /// The window with focus.
    var front: Window? {
        windows.last
    }

    func isOpen(_ window: Window) -> Bool {
        windows.contains { $0 === window }
    }

    /// Opens `window`, or brings it forward if it's already open, and gives it focus.
    func focus(_ window: Window) {
        guard front !== window else {
            return
        }
        front?.resignFocus()
        windows.removeAll { $0 === window }
        windows.append(window)
    }

    /// Closes `window`. The window behind it, if any, gets focus.
    func close(_ window: Window) {
        window.resignFocus()
        windows.removeAll { $0 === window }
    }

    /// Handles a press, bringing forward the topmost window under `point`. Returns whether a
    /// background window took focus, in which case the press should go no further.
    func press(at point: Vector2) -> Bool {
        guard let window = windows.last(where: { $0.contains(point) }), window !== front else {
            return false
        }
        focus(window)
        return true
    }
}
