import Foundation
import DevHubDomain

enum GlabInboxParser {
    private struct TodoDTO: Decodable {
        struct Target: Decodable {
            let iid: Int?
            let title: String?
            let webUrl: String?
        }

        struct Author: Decodable {
            let username: String
        }

        struct Project: Decodable {
            let pathWithNamespace: String
        }

        let id: Int
        let actionName: String
        let targetType: String
        let target: Target?
        let author: Author?
        let body: String?
        let createdAt: Date?
        let state: String
        let project: Project?
    }

    static func items(from data: Data, projectPath: String) throws -> [InboxItem] {
        let todos: [TodoDTO] = try GlabPullRequestParser.decode(data)
        return todos
            .filter { $0.state == "pending" && $0.project?.pathWithNamespace.lowercased() == projectPath.lowercased() }
            .map(item)
    }

    private static func item(_ dto: TodoDTO) -> InboxItem {
        let title = dto.target?.title ?? ""
        let body = dto.body?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return InboxItem(
            id: String(dto.id),
            kind: kind(dto.actionName),
            title: title,
            actor: dto.author?.username,
            excerpt: body.isEmpty || body == title ? nil : body,
            target: target(type: dto.targetType, iid: dto.target?.iid),
            webURL: dto.target?.webUrl.flatMap(URL.init(string:)),
            updatedAt: dto.createdAt
        )
    }

    private static func kind(_ action: String) -> InboxItem.Kind {
        switch action {
        case "mentioned", "directly_addressed": .mention
        case "review_requested": .reviewRequested
        case "assigned": .assigned
        case "approval_required": .approvalRequired
        case "build_failed": .checksFailed
        case "review_submitted", "marked": .comment
        default: .other(action.replacingOccurrences(of: "_", with: " "))
        }
    }

    private static func target(type: String, iid: Int?) -> InboxItem.Target {
        guard let iid else { return .other }
        switch type {
        case "MergeRequest": return .pullRequest(iid: iid)
        case "Issue": return .issue(iid: iid)
        default: return .other
        }
    }
}
