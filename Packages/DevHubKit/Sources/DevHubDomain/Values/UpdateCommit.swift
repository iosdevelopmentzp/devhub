import Foundation

package struct UpdateCommit: Identifiable, Hashable, Sendable {
    package var hash: String
    package var subject: String

    package init(hash: String, subject: String) {
        self.hash = hash
        self.subject = subject
    }

    package var id: String {
        hash
    }
}
