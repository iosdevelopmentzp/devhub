import Foundation

package struct RemoteBranch: Identifiable, Hashable, Sendable {
    package var id: String { name }
    package var name: String
    package var author: String
    package var subject: String
    package var commitDate: Date?

    package init(name: String, author: String, subject: String, commitDate: Date?) {
        self.name = name
        self.author = author
        self.subject = subject
        self.commitDate = commitDate
    }
}
