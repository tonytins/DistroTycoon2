@testable import DistroTycoon
import Raylib
import Testing

private final class FakeWindow: StackedWindow {
    let area: Rectangle
    var resignCount = 0

    init(x: Float) {
        area = Rectangle(x: x, y: 0, width: 100, height: 100)
    }

    func contains(_ point: Vector2) -> Bool {
        CheckCollisionPointRec(point, area)
    }

    func resignFocus() {
        resignCount += 1
    }
}

@Test func openingGivesFocusAndTakesItFromTheOldFront() {
    let stack = WindowStack<FakeWindow>()
    let first = FakeWindow(x: 0)
    let second = FakeWindow(x: 50)
    stack.focus(first)
    stack.focus(second)
    #expect(stack.front === second)
    #expect(first.resignCount == 1)
    #expect(second.resignCount == 0)
}

@Test func focusingTheFrontWindowChangesNothing() {
    let stack = WindowStack<FakeWindow>()
    let window = FakeWindow(x: 0)
    stack.focus(window)
    stack.focus(window)
    #expect(stack.windows.count == 1)
    #expect(window.resignCount == 0)
}

@Test func pressingABackgroundWindowOnlyBringsItForward() {
    let stack = WindowStack<FakeWindow>()
    let back = FakeWindow(x: 0)
    let front = FakeWindow(x: 50)
    stack.focus(back)
    stack.focus(front)
    #expect(stack.press(at: Vector2(x: 10, y: 10)))
    #expect(stack.front === back)
}

@Test func pressingWhereWindowsOverlapGoesToTheTopmost() {
    let stack = WindowStack<FakeWindow>()
    let back = FakeWindow(x: 0)
    let front = FakeWindow(x: 50)
    stack.focus(back)
    stack.focus(front)
    #expect(!stack.press(at: Vector2(x: 75, y: 10)))
    #expect(stack.front === front)
}

@Test func pressingTheDesktopLeavesFocusAlone() {
    let stack = WindowStack<FakeWindow>()
    let window = FakeWindow(x: 0)
    stack.focus(window)
    #expect(!stack.press(at: Vector2(x: 500, y: 500)))
    #expect(stack.front === window)
}

@Test func closingGivesFocusToTheWindowBehind() {
    let stack = WindowStack<FakeWindow>()
    let back = FakeWindow(x: 0)
    let front = FakeWindow(x: 50)
    stack.focus(back)
    stack.focus(front)
    stack.close(front)
    #expect(stack.front === back)
    #expect(!stack.isOpen(front))
    #expect(front.resignCount == 1)
}

@Test func aClosedWindowCanComeBack() {
    let stack = WindowStack<FakeWindow>()
    let window = FakeWindow(x: 0)
    stack.focus(window)
    stack.close(window)
    #expect(stack.front == nil)
    stack.focus(window)
    #expect(stack.front === window)
}
