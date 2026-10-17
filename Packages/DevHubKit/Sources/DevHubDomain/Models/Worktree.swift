import Foundation

package struct Worktree: Identifiable, Hashable, Sendable {
    package enum Kind: Hashable, Sendable {
        case main
        case agent
        case linked
    }

    package let id: String
    package var path: String
    package var branch: String?
    package var head: String
    package var kind: Kind
    package var isLocked: Bool
    package var isMissing: Bool
    package var changedFiles: Int
    package var upstream: String?
    package var isUpstreamGone: Bool
    package var ahead: Int
    package var behind: Int
    package var isMerged: Bool
    package var lastCommit: String
    package var lastActivity: Date?
    package var needsBootstrap: Bool

    package init(
        id: String,
        path: String,
        branch: String?,
        head: String,
        kind: Kind,
        isLocked: Bool,
        isMissing: Bool,
        changedFiles: Int,
        upstream: String?,
        isUpstreamGone: Bool,
        ahead: Int,
        behind: Int,
        isMerged: Bool,
        lastCommit: String,
        lastActivity: Date?,
        needsBootstrap: Bool
    ) {
        self.id = id
        self.path = path
        self.branch = branch
        self.head = head
        self.kind = kind
        self.isLocked = isLocked
        self.isMissing = isMissing
        self.changedFiles = changedFiles
        self.upstream = upstream
        self.isUpstreamGone = isUpstreamGone
        self.ahead = ahead
        self.behind = behind
        self.isMerged = isMerged
        self.lastCommit = lastCommit
        self.lastActivity = lastActivity
        self.needsBootstrap = needsBootstrap
    }

    package var isMain: Bool { kind == .main }
    package var isDirty: Bool { changedFiles > 0 }
    package var displayName: String { branch ?? "detached @ \(head)" }
    package var isFinished: Bool { isMerged || isUpstreamGone }
}
