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
        detail: MergeReadiness? = nil,
        comments: Int = 0,
        pipeline: PipelineInfo? = nil,
        approvedBy: [String] = [],
        labels: [String] = [],
        assignees: [String] = [],
        reviewers: [String] = [],
        target: String = "dev",
        title: String = "ABC-5: Login",
        updatedAt: Date? = nil,
        createdAt: Date? = nil,
        mergedAt: Date? = nil,
        closedAt: Date? = nil,
        mergedBy: String? = nil,
        commitCount: Int? = nil,
        diffStats: DiffStats? = nil,
        threadCount: Int = 0,
        resolvedThreadCount: Int = 0,
        isBehindTarget: Bool = false,
        squashOnMerge: Bool = false,
        removesSourceBranch: Bool? = nil,
        headSHA: String? = "abc123",
        isAutoMergeEnabled: Bool = false,
        permissions: PullRequestPermissions = PullRequestPermissions(canMerge: true, canApprove: true, canRevokeApproval: true, canSetAutoMerge: true)
    ) -> PullRequestSummary {
        PullRequestSummary(
            iid: iid,
            title: title,
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
            labels: labels,
            assignees: assignees,
            reviewers: reviewers,
            createdAt: createdAt,
            mergedAt: mergedAt,
            closedAt: closedAt,
            mergedBy: mergedBy,
            commitCount: commitCount,
            diffStats: diffStats,
            threadCount: threadCount,
            resolvedThreadCount: resolvedThreadCount,
            isBehindTarget: isBehindTarget,
            squashOnMerge: squashOnMerge,
            removesSourceBranch: removesSourceBranch,
            headSHA: headSHA,
            isAutoMergeEnabled: isAutoMergeEnabled,
            permissions: permissions
        )
    }
}
