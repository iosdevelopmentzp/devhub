import Foundation
import DevHubDomain

enum GlabCreatedMergeRequestParser {
    private struct CreatedDTO: Decodable {
        struct Author: Decodable {
            let username: String
        }

        let iid: Int
        let title: String
        let state: String
        let draft: Bool?
        let webUrl: String?
        let author: Author?
        let sourceBranch: String
        let targetBranch: String
        let hasConflicts: Bool?
        let detailedMergeStatus: String?
        let userNotesCount: Int?
        let createdAt: Date?
        let updatedAt: Date?
        let labels: [String]?
        let squash: Bool?
        let forceRemoveSourceBranch: Bool?
        let sha: String?
    }

    static func summary(from data: Data) throws -> MergeRequestSummary {
        let dto: CreatedDTO = try GlabMergeRequestParser.decode(data)
        return MergeRequestSummary(
            iid: dto.iid,
            title: dto.title,
            state: GlabMergeRequestParser.state(dto.state),
            isDraft: dto.draft ?? false,
            webURL: dto.webUrl.flatMap(URL.init(string:)),
            author: dto.author?.username ?? "",
            sourceBranch: dto.sourceBranch,
            targetBranch: dto.targetBranch,
            hasConflicts: dto.hasConflicts ?? false,
            detailedStatus: dto.detailedMergeStatus.map(GlabMergeRequestParser.detail),
            commentCount: dto.userNotesCount ?? 0,
            updatedAt: dto.updatedAt,
            pipeline: nil,
            approvedBy: [],
            labels: dto.labels ?? [],
            createdAt: dto.createdAt,
            squashOnMerge: dto.squash ?? false,
            removesSourceBranch: dto.forceRemoveSourceBranch,
            headSHA: dto.sha
        )
    }
}
