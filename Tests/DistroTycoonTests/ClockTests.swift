@testable import DistroTycoon
import Raylib
import Testing

@Test func aPausedClockPassesNoDays() {
    var clock = GameClock()
    #expect(clock.advance(by: 100) == 0)
}

@Test func timeCarriesOverUntilADayIsDone() {
    var clock = GameClock(speed: .normal)
    var days = 0
    for _ in 0 ..< 40 {
        days += clock.advance(by: 0.1)
    }
    #expect(days == 2)
}

@Test func fastPassesDaysQuicker() {
    var clock = GameClock(speed: .fast)
    var days = 0
    for _ in 0 ..< 20 {
        days += clock.advance(by: 0.1)
    }
    #expect(days == 4)
}

@Test func aLongStallCountsAsOneShortStep() {
    var clock = GameClock(speed: .fast)
    #expect(clock.advance(by: 30) == 0)
    #expect(clock.advance(by: 0.25) == 1)
}

@Test(arguments: [-1.0, .nan, .infinity])
func nonsenseTimeIsIgnored(seconds: Double) {
    var clock = GameClock(speed: .fast)
    #expect(clock.advance(by: seconds) == 0)
}

@Test func statusButtonsAppearOnceRunningAndMarkWhatsOn() {
    #expect(DistroTycoon.statusItems(for: .normal, isRunning: false, isHubbubOpen: false).isEmpty)
    let items = DistroTycoon.statusItems(for: .fast, isRunning: true, isHubbubOpen: true)
    #expect(items.map(\.command) == [.toggleHubbub, .setSpeed(.paused), .setSpeed(.normal), .setSpeed(.fast)])
    #expect(items.map(\.isSelected) == [true, false, false, true])
}

@Test func pressingAStatusItemSendsItsCommand() {
    let bar = MenuBar(menus: [Menu(title: "File", hotkey: "F", items: [])], measure: { $0.count * 10 })
    bar.statusItems = DistroTycoon.statusItems(for: .normal, isRunning: true, isHubbubOpen: false)
    // Items are 26 wide with 2 between, ending 2 from the right edge of an 800-wide bar.
    #expect(bar.update(MenuInput(mouse: Vector2(x: 785, y: 14), isPressed: true), barWidth: 800) == .setSpeed(.fast))
    #expect(bar.tookInput)
    #expect(bar.update(MenuInput(mouse: Vector2(x: 729, y: 14), isPressed: true), barWidth: 800) == .setSpeed(.paused))
    #expect(bar.update(MenuInput(mouse: Vector2(x: 701, y: 14), isPressed: true), barWidth: 800) == .toggleHubbub)
    #expect(bar.update(MenuInput(mouse: Vector2(x: 600, y: 14), isPressed: true), barWidth: 800) == nil)
}
