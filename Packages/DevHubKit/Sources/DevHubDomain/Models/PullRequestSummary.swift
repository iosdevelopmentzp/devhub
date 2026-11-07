import Foundation

package struct PullRequestSummary: Identifiable, Hashable, Sendable {
    package var id: Int { iid }
    package let iid: Int
    package let title: String
    package let state: PullRequestState
    package let isDraft: Bool
    package let webURL: URL?
    package let author: String
    package let sourceBranch: String
    package let targetBranch: String
    package let hasConflicts: Bool
    package let detailedStatus: MergeReadiness?
    package let commentCount: Int
    package let updatedAt: Date?
    package let pipeline: PipelineInfo?
    package let approvedBy: [String]
    package let labels: [String]
    package let assignees: [String]
    package let reviewers: [String]
    package let requestedTeams: [String]
    package let changesRequestedBy: [String]
    package let recentComments: [RecentComment]
    package let createdAt: Date?
    package let mergedAt: Date?
    package let closedAt: Date?
    package let mergedBy: String?
    package let commitCount: Int?
    package let diffStats: DiffStats?
    package let threadCount: Int
    package let resolvedThreadCount: Int
    package let isBehindTarget: Bool
    package let squashOnMerge: Bool
    package let removesSourceBranch: Bool?
    package let headSHA: String?
    package let isAutoMergeEnabled: Bool
    package let permissions: PullRequestPermissions

    package init(
        iid: Int,
        title: String,
        state: PullRequestState,
        isDraft: Bool,
        webURL: URL?,
        author: String,
        sourceBranch: String,
        targetBranch: String,
        hasConflicts: Bool,
        detailedStatus: MergeReadiness?,
        commentCount: Int,
        updatedAt: Date?,
        pipeline: PipelineInfo?,
        approvedBy: [String],
        labels: [String],
        assignees: [String] = [],
        reviewers: [String] = [],
        requestedTeams: [String] = [],
        changesRequestedBy: [String] = [],
        recentComments: [RecentComment] = [],
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
        headSHA: String? = nil,
        isAutoMergeEnabled: Bool = false,
        permissions: PullRequestPermissions = .none
    ) {
        self.iid = iid
        self.title = title
        self.state = state
        self.isDraft = isDraft
        self.webURL = webURL
        self.author = author
        self.sourceBranch = sourceBranch
        self.targetBranch = targetBranch
        self.hasConflicts = hasConflicts
        self.detailedStatus = detailedStatus
        self.commentCount = commentCount
        self.updatedAt = updatedAt
        self.pipeline = pipeline
        self.approvedBy = approvedBy
        self.labels = labels
        self.assignees = assignees
        self.reviewers = reviewers
        self.requestedTeams = requestedTeams
        self.changesRequestedBy = changesRequestedBy
        self.recentComments = recentComments
        self.createdAt = createdAt
        self.mergedAt = mergedAt
        self.closedAt = closedAt
        self.mergedBy = mergedBy
        self.commitCount = commitCount
        self.diffStats = diffStats
        self.threadCount = threadCount
        self.resolvedThreadCount = resolvedThreadCount
        self.isBehindTarget = isBehindTarget
        self.squashOnMerge = squashOnMerge
        self.removesSourceBranch = removesSourceBranch
        self.headSHA = headSHA
        self.isAutoMergeEnabled = isAutoMergeEnabled
        self.permissions = permissions
    }

    package var openThreadCount: Int {
        max(threadCount - resolvedThreadCount, 0)
    }
}
