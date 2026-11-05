@testable import DistroTycoon
import Testing

// A fixed sequence, so a failing roll can be repeated.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
        return state
    }
}

@Test func firstReleaseSetsVersionAndNamesTheDistro() {
    let distro = UserDistro()
    distro.nameDistro(name: "Tuxedo")
    #expect(distro.makeNewRelease() == "1.0 of Tuxedo has been released! Time to sit back and relax")
    #expect(distro.distroVersion == 1)
}

@Test func chanceCardAddsHypeOnlyWhenItHasAMessage() {
    var generator = SeededGenerator(state: 2000)
    var messages = 0
    var misses = 0
    for _ in 0 ..< 5000 {
        let distro = UserDistro()
        if chanceCard(distro: distro, using: &generator) == nil {
            #expect(distro.hype == 0)
            misses += 1
        } else {
            #expect(distro.hype == 5)
            messages += 1
        }
    }
    #expect(messages > 0)
    #expect(misses > 0)
}
