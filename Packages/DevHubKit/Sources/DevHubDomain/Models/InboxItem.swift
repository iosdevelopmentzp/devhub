import Foundation

package struct InboxItem: Identifiable, Hashable, Sendable {
    package enum Kind: Hashable, Sendable {
        case mention
        case reviewRequested
        case assigned
        case comment
        case approvalRequired
        case checksFailed
        case other(String)
    }

    package enum Target: Hashable, Sendable {
        case pullRequest(iid: Int)
        case issue(iid: Int)
        case other
    }

    package let id: String
    package var kind: Kind
    package var title: String
    package var actor: String?
    package var excerpt: String?
    package var target: Target
    package var webURL: URL?
    package var updatedAt: Date?

    package init(id: String, kind: Kind, title: String, actor: String?, excerpt: String?, target: Target, webURL: URL?, updatedAt: Date?) {
        self.id = id
        self.kind = kind
        self.title = title
        self.actor = actor
        self.excerpt = excerpt
        self.target = target
        self.webURL = webURL
        self.updatedAt = updatedAt
    }
}
