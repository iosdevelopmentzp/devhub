import Foundation

package enum ReviewReminderPolicy {

    package static func step(_ waits: [ReviewWait], queue: [Int], hours: Int, now: Date) -> ReviewReminderStep {
        let known = Dictionary(waits.map { ($0.iid, $0) }, uniquingKeysWith: { first, _ in first })
        let tracked = Set(queue).sorted().map { known[$0] ?? ReviewWait(iid: $0, since: now, isReminded: false) }
        let due = tracked.filter { isDue($0, hours: hours, now: now) }
        let dueIDs = Set(due.map(\.iid))
        let updated = tracked.map { wait in
            var wait = wait
            if dueIDs.contains(wait.iid) {
                wait.isReminded = true
            }
            return wait
        }
        return ReviewReminderStep(waits: updated, due: due)
    }

    package static func waitedHours(_ wait: ReviewWait, now: Date) -> Int {
        max(Int(now.timeIntervalSince(wait.since) / 3_600), 1)
    }

    private static func isDue(_ wait: ReviewWait, hours: Int, now: Date) -> Bool {
        hours > 0 && wait.isReminded == false && now.timeIntervalSince(wait.since) >= Double(hours) * 3_600
    }
}
