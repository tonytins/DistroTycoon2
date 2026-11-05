import Foundation
import Hudini
import Raylib

/// A problem with a file the game ships with.
enum ResourceError: LocalizedError {
    case missing(file: String)
    case missingControl(document: String)
    case invalid(file: String, reason: String)

    var errorDescription: String? {
        switch self {
        case let .missing(file):
            "The game's files don't include \(file)."
        case let .missingControl(document):
            "\(document).xml is missing a control the game needs."
        case let .invalid(file, reason):
            "\(file) is invalid: \(reason)"
        }
    }
}

enum Resources {
    /// Reads a bundled UIScript document, and reports attributes it ignored, which are usually typos.
    static func loadScript(named name: String) throws -> UIScript {
        guard let url = Bundle.module.url(forResource: name, withExtension: "xml") else {
            throw ResourceError.missing(file: "\(name).xml")
        }
        let script = try UIScript(contentsOf: url)
        for ignored in script.ignoredAttributes {
            let warning = "\(name).xml line \(ignored.line): \(ignored.element) ignores '\(ignored.attribute)'.\n"
            FileHandle.standardError.write(Data(warning.utf8))
        }
        return script
    }

    /// Loads a bundled font at the size it's mostly drawn at, smoothed for the sizes it's scaled to.
    /// Call this after `InitWindow`, and unload the font before `CloseWindow`.
    static func loadFont(named name: String, size: Int) throws -> Font {
        let file = "Fonts/\(name).ttf"
        guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else {
            throw ResourceError.missing(file: file)
        }
        let font = LoadFontEx(url.path, Int32(size), nil, 0)
        guard IsFontValid(font), font.texture.id != 0 else {
            throw ResourceError.invalid(file: file, reason: "raylib couldn't load it.")
        }
        SetTextureFilter(font.texture, .bilinear)
        return font
    }

    /// Reads the bundled package repository.
    static func loadRepository() throws -> Repository {
        let file = "Repository.json"
        guard let url = Bundle.module.url(forResource: "Repository", withExtension: "json") else {
            throw ResourceError.missing(file: file)
        }
        do {
            return try Repository(data: Data(contentsOf: url))
        } catch {
            throw ResourceError.invalid(file: file, reason: "\(error)")
        }
    }
}
