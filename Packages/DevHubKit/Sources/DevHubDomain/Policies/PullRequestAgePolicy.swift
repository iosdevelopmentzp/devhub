import Foundation

package enum PullRequestAgePolicy {
    package static let staleAfter: TimeInterval = 14 * 24 * 60 * 60

    package static func isStale(_ request: PullRequestSummary, now: Date) -> Bool {
        guard request.state == .opened, let updatedAt = request.updatedAt else { return false }
        return now.timeIntervalSince(updatedAt) >= staleAfter
    }

    package static func isNew(_ request: PullRequestSummary, seenAt: Date?) -> Bool {
        guard let seenAt, let updatedAt = request.updatedAt else { return false }
        return updatedAt > seenAt
    }
}
