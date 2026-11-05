import Foundation

/// The kinds of software a package can be.
enum SoftwareType: String, Decodable, CaseIterable {
    case communication
    case desktopEnvironment
    case game
    case graphics
    case office
    case programming
    case webBrowser

    /// The type as the player reads it.
    var title: String {
        switch self {
        case .communication: "Communication"
        case .desktopEnvironment: "Desktop environment"
        case .game: "Game"
        case .graphics: "Graphics"
        case .office: "Office"
        case .programming: "Programming"
        case .webBrowser: "Web browser"
        }
    }
}

/// A package's upstream project on Hubbub.
struct UpstreamProject: Decodable, Equatable {
    let stars: Int
    /// How busy the project is, from 1 to 5.
    let activity: Int
}

/// Fictional software a distro can ship.
struct Package: Decodable, Equatable {
    let id: String
    let name: String
    let description: String
    let type: SoftwareType
    /// How much the package draws ordinary users.
    let appeal: Int
    /// How much the package impresses enthusiasts.
    let nerdCred: Int
    /// How readily the package produces issues.
    let bugginess: Int
    /// Whether every distro ships it, so the player can't remove it.
    let isPreinstalled: Bool
    let hubbub: UpstreamProject

    private enum CodingKeys: String, CodingKey {
        case id, name, description, type, appeal, nerdCred, bugginess, hubbub
        case isPreinstalled = "preinstalled"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        type = try container.decode(SoftwareType.self, forKey: .type)
        appeal = try container.decode(Int.self, forKey: .appeal)
        nerdCred = try container.decode(Int.self, forKey: .nerdCred)
        bugginess = try container.decode(Int.self, forKey: .bugginess)
        isPreinstalled = try container.decodeIfPresent(Bool.self, forKey: .isPreinstalled) ?? false
        hubbub = try container.decode(UpstreamProject.self, forKey: .hubbub)
    }
}

/// The fictional packages a distro can ship, read from `Repository.json`.
///
/// The file has a `version`. A reader refuses any version it doesn't know, and ignores fields it
/// doesn't know, so later versions can add optional fields without breaking it.
struct Repository: Decodable {
    static let supportedVersion = 1

    /// A problem with the repository's contents, beyond its JSON.
    enum ValidationError: Error, Equatable, CustomStringConvertible {
        case unsupportedVersion(Int)
        case duplicateID(String)
        case emptyField(package: String)
        case negativeValue(package: String)
        case activityOutOfRange(package: String)
        case noDesktopEnvironment
        case emptyIssueTemplate

        var description: String {
            switch self {
            case let .unsupportedVersion(version):
                "version \(version) isn't supported. This game reads version \(Repository.supportedVersion)."
            case let .duplicateID(id):
                "more than one package has the id '\(id)'."
            case let .emptyField(package):
                "package '\(package)' has an empty id, name, or description."
            case let .negativeValue(package):
                "package '\(package)' has a negative number."
            case let .activityOutOfRange(package):
                "package '\(package)' has a Hubbub activity outside 1 to 5."
            case .noDesktopEnvironment:
                "no package is a desktop environment, so no distro could be released."
            case .emptyIssueTemplate:
                "issueTemplates has an empty entry."
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case version, packages, issueTemplates
    }

    /// Every package, sorted by name.
    let packages: [Package]
    /// What an issue can say is wrong, after the package's name. Optional in the file.
    let issueTemplates: [String]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.supportedVersion else {
            throw ValidationError.unsupportedVersion(version)
        }
        packages = try container.decode([Package].self, forKey: .packages)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        issueTemplates = try container.decodeIfPresent([String].self, forKey: .issueTemplates) ?? ["has a bug"]
    }

    /// Reads a repository, and throws when it can't be decoded or a distro couldn't be built from it.
    init(data: Data) throws {
        self = try JSONDecoder().decode(Repository.self, from: data)
        var ids: Set<String> = []
        for package in packages {
            guard ids.insert(package.id).inserted else {
                throw ValidationError.duplicateID(package.id)
            }
            guard ![package.id, package.name, package.description].contains(where: \.isEmpty) else {
                throw ValidationError.emptyField(package: package.id)
            }
            guard [package.appeal, package.nerdCred, package.bugginess, package.hubbub.stars].allSatisfy({ $0 >= 0 }) else {
                throw ValidationError.negativeValue(package: package.id)
            }
            guard (1 ... 5).contains(package.hubbub.activity) else {
                throw ValidationError.activityOutOfRange(package: package.id)
            }
        }
        guard packages.contains(where: { $0.type == .desktopEnvironment }) else {
            throw ValidationError.noDesktopEnvironment
        }
        guard !issueTemplates.contains(where: \.isEmpty) else {
            throw ValidationError.emptyIssueTemplate
        }
    }

    func package(id: String) -> Package? {
        packages.first { $0.id == id }
    }
}
