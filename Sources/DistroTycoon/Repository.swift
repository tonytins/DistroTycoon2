import Foundation

/// The kinds of software a package can be.
enum SoftwareType: String, Decodable, CaseIterable {
    case communication = "Communication"
    case desktopEnvironment = "DesktopEnvironment"
    case game = "Game"
    case graphics = "Graphics"
    case office = "Office"
    case programming = "Programming"
    case webBrowser = "WebBrowser"
}

/// The fictional packages a distro can ship.
struct Repository: Decodable {
    /// A problem with the repository's contents, beyond its JSON.
    enum ValidationError: Error, Equatable {
        case nameDiffersFromKey(key: String, name: String)
        case negativeValue(package: String)
        case noDesktopEnvironment
    }

    private enum CodingKeys: String, CodingKey {
        case packagesByName = "Packages"
    }

    private let packagesByName: [String: Pack]

    /// Every package, sorted by name.
    var packages: [Pack] {
        packagesByName.values.sorted { $0.name < $1.name }
    }

    /// Reads a repository, and throws when it can't be decoded or a distro couldn't be built from it.
    init(data: Data) throws {
        self = try JSONDecoder().decode(Repository.self, from: data)
        for (key, pack) in packagesByName {
            guard key == pack.name else {
                throw ValidationError.nameDiffersFromKey(key: key, name: pack.name)
            }
            guard pack.bugs >= 0, pack.nerdCred >= 0, pack.popularity >= 0, pack.sizeInMB >= 0, pack.version >= 0 else {
                throw ValidationError.negativeValue(package: key)
            }
        }
        guard packagesByName.values.contains(where: { $0.typeOfSoftware == .desktopEnvironment }) else {
            throw ValidationError.noDesktopEnvironment
        }
    }
}

/// Package.
struct Pack: Decodable {
    let name: String
    let bugs: Int
    let description: String
    let nerdCred, popularity, sizeInMB, version: Int
    let isOpenSource: Bool
    let typeOfSoftware: SoftwareType

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case bugs = "Bugs"
        case description = "Description"
        case nerdCred = "NerdCred"
        case popularity = "Popularity"
        case sizeInMB = "SizeInMB"
        case version = "Version"
        case isOpenSource
        case typeOfSoftware = "TypeOfSoftware"
    }
}
