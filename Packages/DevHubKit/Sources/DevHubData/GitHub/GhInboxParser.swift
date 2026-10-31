import Foundation
import DevHubDomain

enum GhInboxParser {
    struct Thread: Equatable {
        var item: InboxItem
        var latestCommentURL: String?
    }

    private struct ThreadDTO: Decodable {
        struct Subject: Decodable {
            let title: String
            let url: String?
            let latestCommentUrl: String?
            let type: String
        }

        struct Repository: Decodable {
            let fullName: String
        }

        let id: String
        let reason: String
        let unread: Bool
        let updatedAt: Date?
        let subject: Subject
        let repository: Repository
    }

    private struct CommentDTO: Decodable {
        struct User: Decodable {
            let login: String
        }

        let user: User?
        let htmlUrl: String?
    }

    static func threads(from data: Data, repository: CodeHost) throws -> [Thread] {
        let threads: [ThreadDTO] = try GhPullRequestParser.decodeREST(data)
        return threads
            .filter { $0.unread && $0.repository.fullName.lowercased() == repository.path.lowercased() }
            .map { thread(from: $0, repository: repository) }
    }

    static func actor(from data: Data) throws -> (login: String?, webURL: URL?) {
        let comment: CommentDTO = try GhPullRequestParser.decodeREST(data)
        return (comment.user?.login, comment.htmlUrl.flatMap(URL.init(string:)))
    }

    private static func thread(from dto: ThreadDTO, repository: CodeHost) -> Thread {
        let target = target(type: dto.subject.type, url: dto.subject.url)
        let item = InboxItem(
            id: dto.id,
            kind: kind(dto.reason),
            title: dto.subject.title,
            actor: nil,
            excerpt: nil,
            target: target,
            webURL: webURL(for: target, repository: repository),
            updatedAt: dto.updatedAt
        )
        let commentURL = dto.subject.latestCommentUrl
        let hasComment = commentURL != nil && commentURL != dto.subject.url && kindHasActorInComment(item.kind)
        return Thread(item: item, latestCommentURL: hasComment ? commentURL : nil)
    }

    private static func kindHasActorInComment(_ kind: InboxItem.Kind) -> Bool {
        switch kind {
        case .mention, .comment: true
        default: false
        }
    }

    private static func kind(_ reason: String) -> InboxItem.Kind {
        switch reason {
        case "mention", "team_mention": .mention
        case "review_requested": .reviewRequested
        case "assign": .assigned
        case "comment", "author", "subscribed", "manual": .comment
        case "approval_requested": .approvalRequired
        case "ci_activity": .checksFailed
        default: .other(reason.replacingOccurrences(of: "_", with: " "))
        }
    }

    private static func target(type: String, url: String?) -> InboxItem.Target {
        guard let number = url.flatMap({ Int($0.split(separator: "/").last ?? "") }) else { return .other }
        switch type {
        case "PullRequest": return .pullRequest(iid: number)
        case "Issue": return .issue(iid: number)
        default: return .other
        }
    }

    private static func webURL(for target: InboxItem.Target, repository: CodeHost) -> URL? {
        switch target {
        case .pullRequest(let iid): URL(string: repository.webURL.absoluteString + "/pull/\(iid)")
        case .issue(let iid): URL(string: repository.webURL.absoluteString + "/issues/\(iid)")
        case .other: nil
        }
    }
}
