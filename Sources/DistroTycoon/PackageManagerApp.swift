import Hudini
import Raylib

/// Chooses what the next release ships, laid out by `packages.xml`.
final class PackageManagerApp: DesktopApp {
    private static let packageList = "packages"
    private static let detailNames = ["packageName", "packageType", "packageDescription", "packageStats", "toggleInclude"]
    private static let descriptionSize = 15

    let title = "Packages"
    let contentSize: Vector2
    let isClosable = true
    let menus = [
        Menu(title: "Packages", hotkey: "P", items: [
            MenuItem(title: "Close", hotkey: "C", command: .closeWindow),
        ]),
    ]

    private let game: Game
    private let appearance: Appearance
    private let view: UIScriptView
    private let list: TextList
    private let descriptionWidth: Int
    private var shownRevision = -1
    private var shownSelection: Int?

    /// Reads the app's layout, and reports a document that can't be read or lacks a control the game needs.
    init(game: Game, appearance: Appearance = .standard) throws {
        let script = try Resources.loadScript(named: "packages")
        let required = [Self.packageList, "summary"] + Self.detailNames
        guard required.allSatisfy({ script.control(named: $0) != nil }), let description = script.control(named: "packageDescription"),
              let width = description.frame.width else {
            throw ResourceError.missingControl(document: "packages")
        }
        view = UIScriptView(script: script, theme: appearance.interface)
        guard let list = view.list(named: Self.packageList) else {
            throw ResourceError.missingControl(document: "packages")
        }
        self.list = list
        self.game = game
        self.appearance = appearance
        descriptionWidth = Int(width)
        contentSize = Vector2(x: script.window.size.width, y: script.window.size.height)
        list.items = game.repository.packages.map { Self.listItem($0, game: game) }
        list.selectedIndex = 0
    }

    /// The package whose details are on show.
    var selectedPackage: Package? {
        list.selectedIndex.flatMap { game.repository.packages.indices.contains($0) ? game.repository.packages[$0] : nil }
    }

    /// What the list shows for each package.
    var lines: [String] {
        list.items
    }

    func refresh() {
        guard shownRevision != game.packagesRevision || shownSelection != list.selectedIndex else {
            return
        }
        shownRevision = game.packagesRevision
        shownSelection = list.selectedIndex
        list.items = game.repository.packages.map { Self.listItem($0, game: game) }
        view.setText(Self.summary(for: game), named: "summary")
        showDetails()
    }

    func update(at origin: Vector2) -> AppAction? {
        for event in view.update(at: origin) where event == .pressed(control: "toggleInclude") {
            toggleSelected()
        }
        refresh()
        return nil
    }

    func draw(at origin: Vector2) {
        view.draw(at: origin)
    }

    /// Adds the shown package to the next release, or takes it out.
    func toggleSelected() {
        guard let package = selectedPackage else {
            return
        }
        game.setIncluded(!game.isIncluded(package), package)
    }

    static func listItem(_ package: Package, game: Game) -> String {
        let mark = package.isPreinstalled ? "[*]" : game.isIncluded(package) ? "[x]" : "[ ]"
        return "\(mark) \(package.name)"
    }

    static func summary(for game: Game) -> String {
        let count = game.includedPackages.count
        let shipping = "Shipping \(count) package\(count == 1 ? "" : "s") next release."
        return game.releaseProblem.map { "\(shipping)\n\($0)" } ?? shipping
    }

    private func showDetails() {
        guard let package = selectedPackage else {
            for name in Self.detailNames {
                view.setHidden(true, named: name)
            }
            return
        }
        for name in Self.detailNames {
            view.setHidden(false, named: name)
        }
        view.setText(package.name, named: "packageName")
        view.setText(package.type.title, named: "packageType")
        let lines = TextWrapper.lines(for: package.description, maximumWidth: descriptionWidth) {
            appearance.textWidth($0, size: Self.descriptionSize)
        }
        view.setText(lines.joined(separator: "\n"), named: "packageDescription")
        view.setText(
            "Appeal \(package.appeal)    Nerd cred \(package.nerdCred)    Bugginess \(package.bugginess)\n"
                + "\(package.hubbub.stars) stars on Hubbub, activity \(package.hubbub.activity) of 5",
            named: "packageStats"
        )
        if package.isPreinstalled {
            view.setText("Preinstalled", named: "toggleInclude")
            view.setDisabled(true, named: "toggleInclude")
        } else {
            view.setText(game.isIncluded(package) ? "Remove from distro" : "Add to distro", named: "toggleInclude")
            view.setDisabled(false, named: "toggleInclude")
        }
    }
}
