import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ReviewReminderPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func hoursAgo(_ hours: Double) -> Date {
        now.addingTimeInterval(-hours * 3_600)
    }

    @Test func aNewRequestInTheQueueStartsWaitingNow() {
        let step = ReviewReminderPolicy.step([], queue: [7, 3, 7], hours: 4, now: now)

        #expect(step.waits == [ReviewWait(iid: 3, since: now, isReminded: false), ReviewWait(iid: 7, since: now, isReminded: false)])
        #expect(step.due.isEmpty)
    }

    @Test func aRequestThatWaitedLongEnoughIsDueOnce() {
        let waits = [ReviewWait(iid: 7, since: hoursAgo(5), isReminded: false), ReviewWait(iid: 8, since: hoursAgo(1), isReminded: false)]

        let first = ReviewReminderPolicy.step(waits, queue: [7, 8], hours: 4, now: now)
        let second = ReviewReminderPolicy.step(first.waits, queue: [7, 8], hours: 4, now: now)

        #expect(first.due.map(\.iid) == [7])
        #expect(first.waits.map(\.isReminded) == [true, false])
        #expect(second.due.isEmpty)
    }

    @Test func aRequestThatLeavesTheQueueIsForgottenAndStartsAgainLater() {
        let waits = [ReviewWait(iid: 7, since: hoursAgo(9), isReminded: true)]

        let left = ReviewReminderPolicy.step(waits, queue: [], hours: 4, now: now)
        let back = ReviewReminderPolicy.step(left.waits, queue: [7], hours: 4, now: now)

        #expect(left.waits.isEmpty)
        #expect(back.waits == [ReviewWait(iid: 7, since: now, isReminded: false)])
    }

    @Test func zeroHoursTurnsTheReminderOff() {
        let waits = [ReviewWait(iid: 7, since: hoursAgo(50), isReminded: false)]

        let step = ReviewReminderPolicy.step(waits, queue: [7], hours: 0, now: now)

        #expect(step.due.isEmpty)
        #expect(step.waits == waits)
    }

    @Test func waitedHoursRoundsDownAndIsAtLeastOne() {
        #expect(ReviewReminderPolicy.waitedHours(ReviewWait(iid: 1, since: hoursAgo(5.7), isReminded: false), now: now) == 5)
        #expect(ReviewReminderPolicy.waitedHours(ReviewWait(iid: 1, since: hoursAgo(0.2), isReminded: false), now: now) == 1)
    }
}
