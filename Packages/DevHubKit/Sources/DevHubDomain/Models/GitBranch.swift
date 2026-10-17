import Foundation

package struct GitBranch: Identifiable, Hashable, Sendable {
    package var id: String { name }
    package var name: String
    package var upstream: String?
    package var ahead: Int
    package var behind: Int
    package var isGone: Bool
    package var isMerged: Bool
    package var subject: String
    package var commitDate: Date?
    package var lastVisited: Date?
    package var worktreePath: String?
    package var author: String?

    package init(
        name: String,
        upstream: String?,
        ahead: Int,
        behind: Int,
        isGone: Bool,
        isMerged: Bool,
        subject: String,
        commitDate: Date?,
        lastVisited: Date?,
        worktreePath: String?,
        author: String? = nil
    ) {
        self.name = name
        self.upstream = upstream
        self.ahead = ahead
        self.behind = behind
        self.isGone = isGone
        self.isMerged = isMerged
        self.subject = subject
        self.commitDate = commitDate
        self.lastVisited = lastVisited
        self.worktreePath = worktreePath
        self.author = author
    }
}
