import DevHubDomain
import Foundation

enum PullRequestSummaryFixture {
    static let open = request(iid: 21, source: "feature/login", state: .opened)

    static func request(
        iid: Int,
        source: String,
        state: PullRequestState,
        author: String = "sam",
        isDraft: Bool = false,
        hasConflicts: Bool = false,
        detail: MergeDetail? = nil,
        comments: Int = 0,
        pipeline: PipelineInfo? = nil,
        approvedBy: [String] = [],
        labels: [String] = [],
        target: String = "dev",
        updatedAt: Date? = nil
    ) -> PullRequestSummary {
        PullRequestSummary(
            iid: iid,
            title: "ABC-5: Login",
            state: state,
            isDraft: isDraft,
            webURL: URL(string: "https://gitlab.example.com/team/app/-/merge_requests/\(iid)"),
            author: author,
            sourceBranch: source,
            targetBranch: target,
            hasConflicts: hasConflicts,
            detailedStatus: detail,
            commentCount: comments,
            updatedAt: updatedAt,
            pipeline: pipeline,
            approvedBy: approvedBy,
            labels: labels
        )
    }
}
