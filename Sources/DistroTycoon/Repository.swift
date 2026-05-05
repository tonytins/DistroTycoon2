
import Foundation

struct Repository: Codable {
    let package: [String: Pack] = [:]

    enum CodingKeys: String, CodingKey {
        case package = "Package"
    }
}

/// Package.
struct Pack: Codable {
    let name: String
    let bugs: Int
    let description: String
    let nerdCred, popularity, sizeInMB, version: Int
    let isOpenSource: Bool
    let typeOfSoftware: String

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
