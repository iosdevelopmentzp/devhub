import Foundation
import DevHubDomain

enum GhPullRequestParser {
    private struct Response<Payload: Decodable>: Decodable {
        struct Failure: Decodable {
            let message: String
        }

        let data: Payload?
        let errors: [Failure]?
    }

    private struct Nodes<Node: Decodable>: Decodable {
        let nodes: [Node]
    }

    private struct Login: Decodable {
        let login: String
    }

    private struct CommentMark: Decodable {
        let databaseId: Int?
        let author: Login?
    }

    private struct ThreadComments: Decodable {
        let comments: Nodes<CommentMark>
    }

    private struct Name: Decodable {
        let name: String
    }

    private struct Count: Decodable {
        let totalCount: Int
    }

    private struct Review: Decodable {
        let state: String
        let author: Login?
    }

    private struct ReviewRequest: Decodable {
        struct Reviewer: Decodable {
            let login: String?
        }

        let requestedReviewer: Reviewer?
    }

    private struct ThreadState: Decodable {
        let isResolved: Bool
    }

    private struct Threads: Decodable {
        let totalCount: Int
        let nodes: [ThreadState]
    }

    private struct Repository: Decodable {
        let viewerPermission: String?
        let viewerDefaultMergeMethod: String?
        let deleteBranchOnMerge: Bool?
        let autoMergeAllowed: Bool?
    }

    private struct PullRequestNode: Decodable {
        let number: Int?
        let title: String?
        let state: String?
        let isDraft: Bool?
        let url: String?
        let author: Login?
        let headRefName: String?
        let baseRefName: String?
        let mergeable: String?
        let mergeStateStatus: String?
        let reviewDecision: String?
        let totalCommentsCount: Int?
        let comments: Nodes<CommentMark>?
        let recentThreads: Nodes<ThreadComments>?
        let additions: Int?
        let deletions: Int?
        let changedFiles: Int?
        let headRefOid: String?
        let createdAt: Date?
        let updatedAt: Date?
        let mergedAt: Date?
        let closedAt: Date?
        let mergedBy: Login?
        let autoMergeRequest: AutoMerge?
        let labels: Nodes<Name>?
        let latestReviews: Nodes<Review>?
        let assignees: Nodes<Login>?
        let reviewRequests: Nodes<ReviewRequest>?
        let reviewThreads: Threads?
        let commitCount: Count?
        let lastCommit: Nodes<GhCheckParser.CommitNode>?
    }

    private struct AutoMerge: Decodable {
        let enabledAt: Date?
    }

    private struct Search: Decodable {
        struct PageInfo: Decodable {
            let hasNextPage: Bool
            let endCursor: String?
        }

        let issueCount: Int
        let pageInfo: PageInfo
        let nodes: [PullRequestNode]
    }

    private struct ListData: Decodable {
        let viewer: Login?
        let repository: Repository?
        let search: Search
    }

    static func list(from data: Data) throws -> PullRequestList {
        let payload: ListData = try payload(data)
        let viewer = payload.viewer?.login ?? ""
        return PullRequestList(
            username: viewer,
            requests: payload.search.nodes.compactMap { summary($0, viewer: viewer, repository: payload.repository) },
            totalCount: payload.search.issueCount,
            endCursor: payload.search.pageInfo.endCursor,
            hasNextPage: payload.search.pageInfo.hasNextPage
        )
    }

    private struct StatusData: Decodable {
        struct Repo: Decodable {
            struct Ref: Decodable {
                let target: GhCheckParser.Commit?
            }

            let pullRequests: Nodes<PullRequestNode>
            let ref: Ref?
        }

        let repository: Repo?
    }

    static func status(from data: Data) throws -> PullRequestStatus {
        let payload: StatusData = try payload(data)
        guard let repository = payload.repository else { throw PullRequestError.command("GitHub did not find the repository") }
        let nodes = repository.pullRequests.nodes
        let request = nodes.first { $0.state == "OPEN" } ?? nodes.first
        let info = request.flatMap { node -> PullRequestInfo? in
            guard let number = node.number else { return nil }
            return PullRequestInfo(
                iid: number,
                title: node.title ?? "",
                state: state(node.state),
                isDraft: node.isDraft ?? false,
                webURL: node.url.flatMap(URL.init(string:)),
                author: node.author?.login ?? "",
                hasConflicts: node.mergeable == "CONFLICTING",
                detailedStatus: detail(node),
                targetBranch: node.baseRefName ?? ""
            )
        }
        let rollup = repository.ref?.target?.statusCheckRollup
        let checksURL = request?.url.map { "\($0)/checks" }
        return PullRequestStatus(pullRequest: info, pipeline: rollup.map { GhCheckParser.pipeline($0, fallbackURL: checksURL) })
    }

    private struct DetailsData: Decodable {
        struct Repo: Decodable {
            let pullRequest: PullRequest?
        }

        struct PullRequest: Decodable {
            let body: String?
            let url: String?
            let reviewThreads: Nodes<Thread>
            let lastCommit: Nodes<GhCheckParser.CommitNode>?
        }

        struct Thread: Decodable {
            let id: String
            let isResolved: Bool
            let path: String?
            let line: Int?
            let originalLine: Int?
            let diffSide: String?
            let comments: Nodes<Comment>
        }

        struct Comment: Decodable {
            let databaseId: Int?
            let body: String
            let author: Login?
            let createdAt: Date?
        }

        let repository: Repo?
    }

    static func details(from data: Data) throws -> PullRequestDetails {
        let payload: DetailsData = try payload(data)
        guard let request = payload.repository?.pullRequest else { throw PullRequestError.command("GitHub did not find the pull request") }
        let threads = request.reviewThreads.nodes
            .filter { $0.isResolved == false }
            .compactMap { thread -> ReviewThread? in
                guard let first = thread.comments.nodes.first else { return nil }
                return ReviewThread(
                    id: thread.id,
                    noteID: first.databaseId,
                    author: first.author?.login ?? "",
                    body: first.body,
                    createdAt: first.createdAt,
                    filePath: thread.path,
                    line: thread.line ?? thread.originalLine,
                    isOnOldLine: thread.diffSide == "LEFT",
                    replies: thread.comments.nodes.dropFirst().map { PullRequestNote(author: $0.author?.login ?? "", body: $0.body, createdAt: $0.createdAt) }
                )
            }
        let rollup = request.lastCommit?.nodes.first?.commit.statusCheckRollup
        return PullRequestDetails(
            description: request.body ?? "",
            threads: threads,
            failedJobs: rollup.map(GhCheckParser.failedJobs) ?? [],
            pipelineDuration: rollup.flatMap(GhCheckParser.duration),
            jobs: rollup.map(GhCheckParser.jobs) ?? []
        )
    }

    private struct ApprovalData: Decodable {
        struct Repo: Decodable {
            struct PullRequest: Decodable {
                let latestReviews: Nodes<IdentifiedReview>
            }

            let pullRequest: PullRequest?
        }

        struct IdentifiedReview: Decodable {
            let id: String
            let state: String
            let author: Login?
        }

        let viewer: Login?
        let repository: Repo?
    }

    static func myApprovalID(from data: Data) throws -> String? {
        let payload: ApprovalData = try payload(data)
        let viewer = payload.viewer?.login
        return payload.repository?.pullRequest?.latestReviews.nodes.first { $0.state == "APPROVED" && $0.author?.login == viewer }?.id
    }

    static func labels(from data: Data) throws -> [String] {
        let labels: [Name] = try decode(data)
        return labels.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func mutation(from data: Data) throws {
        let response: Response<[String: AnyDecodable?]> = try decode(data)
        if let failure = response.errors?.first {
            throw PullRequestError.command(failure.message)
        }
    }

    static func decodeREST<Value: Decodable>(_ data: Data) throws -> Value {
        try decode(data, keys: .convertFromSnakeCase)
    }

    static func decode<Value: Decodable>(_ data: Data) throws -> Value {
        try decode(data, keys: .useDefaultKeys)
    }

    private static func decode<Value: Decodable>(_ data: Data, keys: JSONDecoder.KeyDecodingStrategy) throws -> Value {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keys
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            return ISO8601.date(from: text) ?? .distantPast
        }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw PullRequestError.command("Unexpected answer from GitHub: \(error.localizedDescription)")
        }
    }

    private static func payload<Payload: Decodable>(_ data: Data) throws -> Payload {
        let response: Response<Payload> = try decode(data)
        guard let payload = response.data else {
            throw PullRequestError.command(response.errors?.first?.message ?? "Empty answer from GitHub")
        }
        return payload
    }

    private static func summary(_ node: PullRequestNode, viewer: String, repository: Repository?) -> PullRequestSummary? {
        guard let number = node.number else { return nil }
        let threads = node.reviewThreads
        let author = node.author?.login ?? ""
        let canWrite = ["ADMIN", "MAINTAIN", "WRITE"].contains(repository?.viewerPermission ?? "")
        return PullRequestSummary(
            iid: number,
            title: node.title ?? "",
            state: state(node.state),
            isDraft: node.isDraft ?? false,
            webURL: node.url.flatMap(URL.init(string:)),
            author: author,
            sourceBranch: node.headRefName ?? "",
            targetBranch: node.baseRefName ?? "",
            hasConflicts: node.mergeable == "CONFLICTING",
            detailedStatus: detail(node),
            commentCount: node.totalCommentsCount ?? 0,
            updatedAt: node.updatedAt,
            pipeline: node.lastCommit?.nodes.first?.commit.statusCheckRollup.map { GhCheckParser.pipeline($0, fallbackURL: node.url.map { "\($0)/checks" }) },
            approvedBy: (node.latestReviews?.nodes ?? []).filter { $0.state == "APPROVED" }.compactMap { $0.author?.login },
            labels: node.labels?.nodes.map(\.name) ?? [],
            assignees: node.assignees?.nodes.map(\.login) ?? [],
            reviewers: (node.reviewRequests?.nodes ?? []).compactMap { $0.requestedReviewer?.login },
            changesRequestedBy: (node.latestReviews?.nodes ?? []).filter { $0.state == "CHANGES_REQUESTED" }.compactMap { $0.author?.login },
            recentComments: recentComments(node),
            createdAt: node.createdAt,
            mergedAt: node.mergedAt,
            closedAt: node.closedAt,
            mergedBy: node.mergedBy?.login,
            commitCount: node.commitCount?.totalCount,
            diffStats: node.additions.map { DiffStats(additions: $0, deletions: node.deletions ?? 0, fileCount: node.changedFiles ?? 0) },
            threadCount: threads?.totalCount ?? 0,
            resolvedThreadCount: threads?.nodes.count(where: \.isResolved) ?? 0,
            isBehindTarget: node.mergeStateStatus == "BEHIND",
            squashOnMerge: repository?.viewerDefaultMergeMethod == "SQUASH",
            removesSourceBranch: repository?.deleteBranchOnMerge,
            headSHA: node.headRefOid,
            isAutoMergeEnabled: node.autoMergeRequest != nil,
            permissions: PullRequestPermissions(
                canMerge: canWrite,
                canApprove: author != viewer && repository?.viewerPermission != nil,
                canRevokeApproval: canWrite,
                canSetAutoMerge: canWrite && repository?.autoMergeAllowed == true,
                canRequestChanges: author != viewer && repository?.viewerPermission != nil
            )
        )
    }

    private static func state(_ name: String?) -> PullRequestState {
        switch name {
        case "OPEN": .opened
        case "MERGED": .merged
        case "CLOSED": .closed
        default: .other(name?.lowercased() ?? "")
        }
    }

    private static func recentComments(_ node: PullRequestNode) -> [RecentComment] {
        let marks = (node.comments?.nodes ?? []) + (node.recentThreads?.nodes ?? []).flatMap(\.comments.nodes)
        var comments: [RecentComment] = []
        for mark in marks {
            guard let id = mark.databaseId else { continue }
            let comment = RecentComment(id: String(id), author: mark.author?.login ?? "")
            guard comments.contains(comment) == false else { continue }
            comments.append(comment)
        }
        return comments
    }

    private static func detail(_ node: PullRequestNode) -> MergeReadiness? {
        if node.isDraft == true { return .draftStatus }
        let rollup = node.lastCommit?.nodes.first?.commit.statusCheckRollup?.state
        switch node.mergeStateStatus {
        case "CLEAN", "HAS_HOOKS", "UNSTABLE": return .mergeable
        case "DIRTY": return .other("conflict")
        case "BEHIND": return .needRebase
        case "DRAFT": return .draftStatus
        case "BLOCKED":
            if node.reviewDecision == "REVIEW_REQUIRED" || node.reviewDecision == "CHANGES_REQUESTED" { return .notApproved }
            if rollup == "PENDING" || rollup == "EXPECTED" { return .ciStillRunning }
            if rollup == "FAILURE" || rollup == "ERROR" { return .ciMustPass }
            let threads = node.reviewThreads
            if let threads, threads.nodes.contains(where: { $0.isResolved == false }) { return .discussionsNotResolved }
            return .other("blocked")
        case nil: return nil
        default: return .other("checking")
        }
    }
}

private struct AnyDecodable: Decodable {}
