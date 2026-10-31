import Foundation

package struct CIAutoRerunPlan: Hashable, Sendable, Codable {
    package let iid: Int
    package let maxAttempts: Int
    package var attempts: Int
    package var handledWorkflowIDs: Set<String>
    package var lastRerunAt: Date?

    package init(iid: Int, maxAttempts: Int, attempts: Int, handledWorkflowIDs: Set<String>, lastRerunAt: Date?) {
        self.iid = iid
        self.maxAttempts = maxAttempts
        self.attempts = attempts
        self.handledWorkflowIDs = handledWorkflowIDs
        self.lastRerunAt = lastRerunAt
    }

    package var attemptsLeft: Int {
        max(0, maxAttempts - attempts)
    }
}
