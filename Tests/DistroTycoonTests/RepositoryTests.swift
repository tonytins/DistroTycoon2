@testable import DistroTycoon
import Foundation
import Testing

private func package(
    id: String = "midget",
    name: String = "Midget",
    type: String = "desktopEnvironment",
    appeal: Int = 1,
    activity: Int = 2,
    extra: String = ""
) -> String {
    """
    {"id": "\(id)", "name": "\(name)", "description": "Small", "type": "\(type)", "appeal": \(appeal),
    "nerdCred": 1, "bugginess": 1, "hubbub": {"stars": 10, "activity": \(activity)}\(extra)}
    """
}

private func document(version: Int = 1, _ packages: String...) -> Data {
    Data(#"{"version": \#(version), "packages": [\#(packages.joined(separator: ","))]}"#.utf8)
}

@Test func bundledRepositoryLoadsEveryPackage() throws {
    let repository = try Resources.loadRepository()
    #expect(repository.packages.count == 20)
    #expect(repository.packages.map { $0.name.lowercased() } == repository.packages.map { $0.name.lowercased() }.sorted())
    #expect(repository.package(id: "okayoffice")?.type == .office)
    #expect(repository.package(id: "hubbub")?.isPreinstalled == true)
    #expect(repository.packages.filter(\.isPreinstalled).count == 1)
    #expect(repository.packages.filter { $0.type == .desktopEnvironment }.count == 3)
}

@Test func aValidDocumentLoadsWithDefaults() throws {
    let repository = try Repository(data: document(package()))
    #expect(repository.packages.count == 1)
    #expect(repository.packages[0].isPreinstalled == false)
}

@Test func unknownFieldsAreIgnored() throws {
    let repository = try Repository(data: document(package(extra: #", "license": "GPL", "future": {"a": 1}"#)))
    #expect(repository.packages.count == 1)
}

@Test func anotherVersionIsRefused() {
    #expect(throws: Repository.ValidationError.unsupportedVersion(2)) {
        try Repository(data: document(version: 2, package()))
    }
}

@Test func aDuplicateIDIsRefused() {
    #expect(throws: Repository.ValidationError.duplicateID("midget")) {
        try Repository(data: document(package(), package(name: "Other")))
    }
}

@Test func anEmptyNameIsRefused() {
    #expect(throws: Repository.ValidationError.emptyField(package: "midget")) {
        try Repository(data: document(package(name: "")))
    }
}

@Test func aNegativeValueIsRefused() {
    #expect(throws: Repository.ValidationError.negativeValue(package: "midget")) {
        try Repository(data: document(package(appeal: -1)))
    }
}

@Test(arguments: [0, 6])
func activityOutsideOneToFiveIsRefused(activity: Int) {
    #expect(throws: Repository.ValidationError.activityOutOfRange(package: "midget")) {
        try Repository(data: document(package(activity: activity)))
    }
}

@Test func aRepositoryWithoutADesktopEnvironmentIsRefused() {
    #expect(throws: Repository.ValidationError.noDesktopEnvironment) {
        try Repository(data: document(package(type: "game")))
    }
}

@Test func anUnknownSoftwareTypeIsRefused() {
    #expect(throws: DecodingError.self) {
        try Repository(data: document(package(type: "toaster")))
    }
}

@Test func malformedJSONIsRefused() {
    #expect(throws: DecodingError.self) {
        try Repository(data: Data("{".utf8))
    }
}
