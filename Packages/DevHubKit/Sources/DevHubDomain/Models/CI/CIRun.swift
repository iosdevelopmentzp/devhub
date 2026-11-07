import Foundation

package struct CIRun: Hashable, Sendable {
    package let id: String
    package let status: CheckStatus
    package let branch: String?
    package let revision: String?
    package let subject: String?
    package let createdAt: Date?

    package init(id: String, status: CheckStatus, branch: String?, revision: String?, subject: String?, createdAt: Date?) {
        self.id = id
        self.status = status
        self.branch = branch
        self.revision = revision
        self.subject = subject
        self.createdAt = createdAt
    }
}
