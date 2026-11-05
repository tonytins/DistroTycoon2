import Foundation
import Hudini
import Raylib

/// The window that asks the player to name their distro, laid out by `createdistro.xml`.
final class CreateDistroWindow {
    private static let nameField = "distroName"
    private static let submitButton = "submit"

    private let frame = WindowFrame(title: "Create your Distro", theme: Palette.theme)
    private let view: UIScriptView
    private let size: Vector2

    /// Reads the window's layout, and reports a document that can't be read or lacks a control the
    /// game needs.
    init() throws {
        let script = try Resources.loadScript(named: "createdistro")
        guard script.control(named: Self.nameField)?.type == .textField, script.control(named: Self.submitButton)?.type == .button else {
            throw ResourceError.missingControl(document: "createdistro")
        }
        view = UIScriptView(script: script, theme: Palette.theme)
        size = Vector2(x: script.window.size.width, y: script.window.size.height + Float(WindowFrame.titleHeight))
        frame.showsCloseButton = false
    }

    /// Handles this frame's input and returns the name the player submitted, if any.
    func update() -> String? {
        let bounds = bounds
        if frame.followPointer(in: bounds) {
            return nil
        }
        view.setDisabled(Self.cleaned(view.text(named: Self.nameField) ?? "") == nil, named: Self.submitButton)
        for event in view.update(at: Self.origin(in: bounds)) {
            switch event {
            case let .submitted(_, text):
                return Self.cleaned(text)
            case .pressed(Self.submitButton):
                return Self.cleaned(view.text(named: Self.nameField) ?? "")
            default:
                break
            }
        }
        return nil
    }

    /// Draws the window under the menu bar.
    func draw() {
        let bounds = bounds
        frame.draw(in: bounds)
        view.draw(at: Self.origin(in: bounds))
    }

    /// Returns a name with its surrounding spaces removed, or `nil` when nothing else is left.
    static func cleaned(_ name: String) -> String? {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
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
