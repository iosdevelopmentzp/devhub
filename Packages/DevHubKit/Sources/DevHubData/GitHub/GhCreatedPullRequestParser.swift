import Foundation
import DevHubDomain

enum GhCreatedPullRequestParser {
    private struct CreatedDTO: Decodable {
        struct User: Decodable {
            let login: String
        }

        struct Ref: Decodable {
            let ref: String
            let sha: String?
        }

        struct Label: Decodable {
            let name: String
        }

        let number: Int
        let title: String
        let state: String
        let draft: Bool?
        let htmlUrl: String?
        let user: User?
        let head: Ref
        let base: Ref
        let createdAt: Date?
        let updatedAt: Date?
        let labels: [Label]?
    }

    static func summary(from data: Data, labels: [String]) throws -> MergeRequestSummary {
        let dto: CreatedDTO = try GhPullRequestParser.decodeREST(data)
        return MergeRequestSummary(
            iid: dto.number,
            title: dto.title,
            state: dto.state == "open" ? .opened : .closed,
            isDraft: dto.draft ?? false,
            webURL: dto.htmlUrl.flatMap(URL.init(string:)),
            author: dto.user?.login ?? "",
            sourceBranch: dto.head.ref,
            targetBranch: dto.base.ref,
            hasConflicts: false,
            detailedStatus: nil,
            commentCount: 0,
            updatedAt: dto.updatedAt,
            pipeline: nil,
            approvedBy: [],
            labels: labels.isEmpty ? dto.labels?.map(\.name) ?? [] : labels,
            createdAt: dto.createdAt,
            headSHA: dto.head.sha
        )
    }
}
