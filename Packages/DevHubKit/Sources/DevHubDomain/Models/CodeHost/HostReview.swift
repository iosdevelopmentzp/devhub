import Foundation

package struct HostReview: Hashable, Sendable {
    package let submittedAt: Date
    package let state: String

    package init(submittedAt: Date, state: String) {
        self.submittedAt = submittedAt
        self.state = state
    }
}
