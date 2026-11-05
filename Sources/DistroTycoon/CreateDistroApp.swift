import Foundation
import Hudini
import Raylib

/// Asks the player to name their distro, laid out by `createdistro.xml`.
final class CreateDistroApp: DesktopApp {
    private static let nameField = "distroName"
    private static let submitButton = "submit"

    let title = "Create your Distro"
    let contentSize: Vector2
    // The game can't start without a name.
    let isClosable = false

    private let view: UIScriptView

    /// Reads the app's layout, and reports a document that can't be read or lacks a control the game needs.
    init(appearance: Appearance = .standard) throws {
        let script = try Resources.loadScript(named: "createdistro")
        guard script.control(named: Self.nameField)?.type == .textField, script.control(named: Self.submitButton)?.type == .button else {
            throw ResourceError.missingControl(document: "createdistro")
        }
        view = UIScriptView(script: script, theme: appearance.interface)
        contentSize = Vector2(x: script.window.size.width, y: script.window.size.height)
    }

    func update(at origin: Vector2) -> AppAction? {
        view.setDisabled(Self.cleaned(view.text(named: Self.nameField) ?? "") == nil, named: Self.submitButton)
        for event in view.update(at: origin) {
            switch event {
            case let .submitted(_, text):
                return Self.cleaned(text).map(AppAction.nameChosen)
            case .pressed(Self.submitButton):
                return Self.cleaned(view.text(named: Self.nameField) ?? "").map(AppAction.nameChosen)
            default:
                break
            }
        }
        return nil
    }

    func draw(at origin: Vector2) {
        view.draw(at: origin)
    }

    func resignFocus() {
        view.clearFocus()
    }

    /// Returns a name with its surrounding spaces removed, or `nil` when nothing else is left.
    static func cleaned(_ name: String) -> String? {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
