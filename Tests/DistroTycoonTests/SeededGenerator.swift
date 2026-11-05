/// A fixed sequence of random numbers, so a failing run can be repeated.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
        return state ^ (state >> 29)
    }
}
