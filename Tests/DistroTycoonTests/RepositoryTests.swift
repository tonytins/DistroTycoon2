@testable import DistroTycoon
import Foundation
import Testing

private func document(key: String = "Midget", name: String = "Midget", bugs: Int = 1, type: String = "DesktopEnvironment") -> Data {
    Data("""
    {"Packages": {"\(key)": {"Name": "\(name)", "Bugs": \(bugs), "Description": "Small", "NerdCred": 1,
    "Popularity": 1, "SizeInMB": 1, "Version": 1, "isOpenSource": true, "TypeOfSoftware": "\(type)"}}}
    """.utf8)
}

@Test func bundledRepositoryLoadsEveryPackage() throws {
    let repository = try Resources.loadRepository()
    #expect(repository.packages.count == 19)
    #expect(repository.packages.map(\.name) == repository.packages.map(\.name).sorted())
    #expect(repository.packages.contains { $0.name == "OkayOffice" && $0.typeOfSoftware == .office })
    #expect(repository.packages.filter { $0.typeOfSoftware == .desktopEnvironment }.count >= 1)
}

@Test func aValidDocumentLoads() throws {
    #expect(try Repository(data: document()).packages.count == 1)
}

@Test func aNameThatDiffersFromItsKeyIsRefused() {
    #expect(throws: Repository.ValidationError.nameDiffersFromKey(key: "Midget", name: "Other")) {
        try Repository(data: document(name: "Other"))
    }
}

@Test func aNegativeValueIsRefused() {
    #expect(throws: Repository.ValidationError.negativeValue(package: "Midget")) {
        try Repository(data: document(bugs: -1))
    }
}

@Test func aRepositoryWithoutADesktopEnvironmentIsRefused() {
    #expect(throws: Repository.ValidationError.noDesktopEnvironment) {
        try Repository(data: document(type: "Game"))
    }
}

@Test func anUnknownSoftwareTypeIsRefused() {
    #expect(throws: DecodingError.self) {
        try Repository(data: document(type: "Toaster"))
    }
}

@Test func malformedJSONIsRefused() {
    #expect(throws: DecodingError.self) {
        try Repository(data: Data("{".utf8))
    }
}
