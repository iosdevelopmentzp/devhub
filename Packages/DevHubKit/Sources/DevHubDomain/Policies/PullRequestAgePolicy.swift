import Foundation

package enum PullRequestAgePolicy {
    package static func isStale(_ request: PullRequestSummary, now: Date, staleDays: Int) -> Bool {
        guard request.state == .opened, let updatedAt = request.updatedAt else { return false }
        return now.timeIntervalSince(updatedAt) >= TimeInterval(staleDays) * 24 * 60 * 60
    }

    package static func isNew(_ request: PullRequestSummary, seenAt: Date?) -> Bool {
        guard let seenAt, let updatedAt = request.updatedAt else { return false }
        return updatedAt > seenAt
    }
}
