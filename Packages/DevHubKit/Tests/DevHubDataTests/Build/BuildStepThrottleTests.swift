import Foundation
import Testing
@testable import DevHubData

@Suite struct BuildStepThrottleTests {
    private let start = ContinuousClock.now

    private func emitted(at offsets: [Int]) -> [Bool] {
        var throttle = BuildStepThrottle(interval: .milliseconds(200))
        return offsets.map { throttle.shouldEmit(at: start + .milliseconds($0)) }
    }

    @Test func theFirstStepIsEmitted() {
        #expect(emitted(at: [0]) == [true])
    }

    @Test func stepsInsideTheIntervalAreDropped() {
        #expect(emitted(at: [0, 50, 199]) == [true, false, false])
    }

    @Test func aStepAfterTheIntervalIsEmittedAndRestartsIt() {
        #expect(emitted(at: [0, 200, 300, 400]) == [true, true, false, true])
    }
}
