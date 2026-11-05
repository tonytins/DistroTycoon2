import Hudini
import Raylib

/// The pane that drops down from Hubbub's button in the menu bar, laid out by `hubbub.xml`. It
/// shows the project's numbers and issues, and chooses the release cycle.
final class HubbubPane {
    private static let cycleButtons: [(name: String, cycle: ReleaseCycle)] = [
        ("noSchedule", .noSchedule), ("rolling", .rolling), ("predictable", .predictable),
    ]
    private static let required = ["stats", "issues", "fix", "fixStatus", "lts", "schedule"] + cycleButtons.map(\.name)
    private static let edgeGap: Float = 8
    private static let barGap: Float = 4

    private let game: Game
    private let appearance: Appearance
    private let view: UIScriptView
    private let list: TextList
    private let size: Vector2
    private var shownRevision = -1
    private var shownIssueIDs: [Int] = []

    private(set) var isOpen = false
    /// Whether the last update used the frame's input, so that nothing under the pane should.
    private(set) var tookInput = false

    /// Reads the pane's layout, and reports a document that can't be read or lacks a control the game needs.
    init(game: Game, appearance: Appearance = .standard) throws {
        let script = try Resources.loadScript(named: "hubbub")
        guard Self.required.allSatisfy({ script.control(named: $0) != nil }) else {
            throw ResourceError.missingControl(document: "hubbub")
        }
        view = UIScriptView(script: script, theme: appearance.interface)
        guard let list = view.list(named: "issues") else {
            throw ResourceError.missingControl(document: "hubbub")
        }
        self.list = list
        self.game = game
        self.appearance = appearance
        size = Vector2(x: script.window.size.width, y: script.window.size.height)
    }

    /// What the issue list shows.
    var lines: [String] {
        list.items
    }

    func toggle() {
        isOpen.toggle()
        if isOpen {
            refresh()
        }
    }

    /// Handles a frame's input. While open, the pane takes all of it: Escape or a press outside
    /// closes it, so a stray click can't reach the desktop.
    func update(_ input: MenuInput, screenWidth: Float) {
        tookInput = isOpen
        guard isOpen else {
            return
        }
        let bounds = bounds(screenWidth: screenWidth)
        if input.keys.contains(.escape) || (input.isPressed && !CheckCollisionPointRec(input.mouse, bounds)) {
            isOpen = false
            return
        }
        for case let .pressed(control) in view.update(at: Vector2(x: bounds.x, y: bounds.y)) {
            press(control)
        }
        refresh()
    }

    /// Acts on a press of one of the pane's buttons.
    func press(_ control: String) {
        if control == "fix" {
            if let index = list.selectedIndex, shownIssueIDs.indices.contains(index) {
                game.startFixing(issueID: shownIssueIDs[index])
            }
        } else if control == "lts" {
            game.setIncludesLTS(!game.includesLTS)
        } else if let cycle = Self.cycleButtons.first(where: { $0.name == control })?.cycle {
            game.setCycle(cycle)
        }
        refresh()
    }

    /// Catches up with the game.
    func refresh() {
        view.setText(Self.stats(for: game), named: "stats")
        view.setText(Self.fixStatus(for: game), named: "fixStatus")
        view.setText(Self.schedule(for: game), named: "schedule")
        if shownRevision != game.issuesRevision {
            shownRevision = game.issuesRevision
            let selectedID = list.selectedIndex.flatMap { shownIssueIDs.indices.contains($0) ? shownIssueIDs[$0] : nil }
            shownIssueIDs = game.openIssues.map(\.id)
            list.items = game.openIssues.map { Self.line(for: $0, game: game) }
            list.selectedIndex = selectedID.flatMap { shownIssueIDs.firstIndex(of: $0) }
        }
        view.setDisabled(game.fix != nil || list.selectedIndex == nil, named: "fix")
        for (name, cycle) in Self.cycleButtons {
            view.setSelected(game.cycle == cycle, named: name)
            view.setDisabled(game.distro.distroName.isEmpty, named: name)
        }
        view.setHidden(game.cycle != .predictable, named: "lts")
        view.setSelected(game.includesLTS, named: "lts")
    }

    /// Selects the issue at `index` in the list, as a click would.
    func selectIssue(at index: Int?) {
        list.selectedIndex = index
        refresh()
    }

    /// Draws the pane under its button. Draw it before the menu bar, so the bar's menus cover it.
    func draw(screenWidth: Float) {
        guard isOpen else {
            return
        }
        let bounds = bounds(screenWidth: screenWidth)
        let origin = Vector2(x: bounds.x, y: bounds.y)
        // Opaque, unlike the windows, so nothing behind the pane shows through its text.
        var fill = appearance.interface.panel
        fill.a = 255
        appearance.fillRounded(bounds, fill)
        appearance.outlineRounded(bounds, appearance.barEdge)
        view.draw(at: origin)
        // Buttons without images look the same selected or not, so the chosen ones get a ring.
        for name in Self.cycleButtons.map(\.name) + ["lts"] where view.isSelected(named: name) && !view.isHidden(named: name) {
            if let button = view.bounds(named: name, at: origin) {
                appearance.outlineRounded(button, appearance.interface.accent, thickness: 2)
            }
        }
    }

    static func line(for issue: ReportedIssue, game: Game) -> String {
        let name = game.repository.package(id: issue.packageID)?.name ?? issue.packageID
        return "#\(issue.id) \(name) \(issue.summary) (\(issue.effort) day\(issue.effort == 1 ? "" : "s"))"
    }

    static func stats(for game: Game) -> String {
        "Users \(game.distro.users)    Stars \(game.stars)    Buzz \(game.distro.buzz)\n"
            + "Open issues \(game.openIssues.count)    Fixed, not yet shipped \(game.fixedIssues.count)"
    }

    static func fixStatus(for game: Game) -> String {
        let doing = game.fix.map { "Fixing #\($0.issue.id), \($0.daysLeft) day\($0.daysLeft == 1 ? "" : "s") left." }
            ?? (game.openIssues.isEmpty ? "Nothing to fix." : "Pick an issue, then Fix.")
        return game.cycle == .rolling ? "\(doing)\nFixes ship the next day." : "\(doing)\nFixes ship with the next release."
    }

    static func schedule(for game: Game) -> String {
        switch game.cycle {
        case .noSchedule:
            return "Release from the \(game.distro.distroName.isEmpty ? "system" : game.distro.distroName) menu whenever you like."
        case .rolling:
            return "Changes reach users the day after they're made."
        case .predictable:
            var lines: [String] = []
            if let due = game.dueDay {
                lines.append("Next release \(game.nextReleaseIsLTS ? "(LTS) " : "")due day \(due).")
            }
            if let end = game.supportEndDay {
                lines.append("\(game.versionLabel) supported until day \(end).")
            }
            return lines.joined(separator: "\n")
        }
    }

    private func bounds(screenWidth: Float) -> Rectangle {
        Rectangle(
            x: max(Self.edgeGap, screenWidth - size.x - Self.edgeGap),
            y: Float(MenuBar.height) + Self.barGap,
            width: size.x,
            height: size.y
        )
    }
}
