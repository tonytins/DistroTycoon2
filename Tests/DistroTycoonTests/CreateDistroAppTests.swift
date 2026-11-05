@testable import DistroTycoon
import Testing

@Test func bundledLayoutLoadsCleanly() throws {
    let script = try Resources.loadScript(named: "createdistro")
    #expect(script.ignoredAttributes.isEmpty)
    #expect(script.control(named: "distroName")?.type == .textField)
    #expect(script.control(named: "submit")?.type == .button)
}

@Test(arguments: zip(["Tuxedo", "  Tuxedo Linux ", "", "   "], ["Tuxedo", "Tuxedo Linux", nil, nil]))
func namesAreTrimmedAndBlankOnesRefused(name: String, expected: String?) {
    #expect(CreateDistroApp.cleaned(name) == expected)
}
