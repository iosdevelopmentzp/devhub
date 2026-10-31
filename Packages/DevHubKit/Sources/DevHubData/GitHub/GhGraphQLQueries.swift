import Foundation
import DevHubDomain

enum GhGraphQLQueries {
    private static let checks = """
    lastCommit: commits(last: 1) { nodes { commit { statusCheckRollup { state contexts(first: 50) { nodes { __typename \
    ... on CheckRun { databaseId name title conclusion status detailsUrl startedAt completedAt checkSuite { workflowRun { databaseId workflow { name } } } } \
    ... on StatusContext { context state targetUrl } } } } } } }
    """

    private static let fields = """
    number title state isDraft url author { login } headRefName baseRefName mergeable mergeStateStatus reviewDecision \
    totalCommentsCount additions deletions changedFiles headRefOid createdAt updatedAt mergedAt closedAt mergedBy { login } \
    autoMergeRequest { enabledAt } labels(first: 20) { nodes { name } } latestReviews(first: 20) { nodes { state author { login } } } \
    assignees(first: 10) { nodes { login } } reviewRequests(first: 10) { nodes { requestedReviewer { ... on User { login } } } } \
    reviewThreads(first: 100) { totalCount nodes { isResolved } } commitCount: commits { totalCount } \(checks)
    """

    private static let repositoryFields = "viewerPermission viewerDefaultMergeMethod deleteBranchOnMerge autoMergeAllowed"

    static let list = """
    query($search: String!, $owner: String!, $name: String!, $after: String) { viewer { login } \
    repository(owner: $owner, name: $name) { \(repositoryFields) } \
    search(query: $search, type: ISSUE, first: 50, after: $after) { issueCount pageInfo { hasNextPage endCursor } \
    nodes { ... on PullRequest { \(fields) } } } }
    """

    static let status = """
    query($owner: String!, $name: String!, $branch: String!, $ref: String!) { repository(owner: $owner, name: $name) { \
    pullRequests(headRefName: $branch, first: 5, orderBy: { field: UPDATED_AT, direction: DESC }) { nodes { \
    number title state isDraft url author { login } mergeable mergeStateStatus reviewDecision baseRefName \
    reviewThreads(first: 100) { totalCount nodes { isResolved } } \(checks) } } \
    ref(qualifiedName: $ref) { target { ... on Commit { statusCheckRollup { state contexts(first: 50) { nodes { __typename \
    ... on CheckRun { name conclusion status detailsUrl startedAt completedAt checkSuite { workflowRun { databaseId } } } \
    ... on StatusContext { context state targetUrl } } } } } } } } }
    """

    static let details = """
    query($owner: String!, $name: String!, $number: Int!) { repository(owner: $owner, name: $name) { pullRequest(number: $number) { \
    body url reviewThreads(first: 100) { nodes { id isResolved path line originalLine diffSide \
    comments(first: 100) { nodes { databaseId body author { login } createdAt } } } } \(checks) } } }
    """

    static let myApproval = """
    query($owner: String!, $name: String!, $number: Int!) { viewer { login } repository(owner: $owner, name: $name) { \
    pullRequest(number: $number) { latestReviews(first: 50) { nodes { id state author { login } } } } } }
    """

    static let dismissReview = "mutation($id: ID!, $message: String!) { dismissPullRequestReview(input: { pullRequestReviewId: $id, message: $message }) { clientMutationId } }"

    static let resolveThread = "mutation($id: ID!) { resolveReviewThread(input: { threadId: $id }) { clientMutationId } }"

    static let reply = "mutation($id: ID!, $body: String!) { addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: $id, body: $body }) { clientMutationId } }"

    static func search(_ query: PullRequestQuery, repository: String) -> String {
        var parts = ["repo:\(repository)", "is:pr"]
        switch query.scope {
        case .mine: parts.append("author:@me")
        case .reviewing: parts.append("review-requested:@me")
        case .assigned: parts.append("assignee:@me")
        case .all: break
        }
        let state: PullRequestStateFilter = query.scope == .reviewing ? .opened : query.state
        switch state {
        case .opened: parts.append("is:open")
        case .merged: parts.append("is:merged")
        case .closed: parts += ["is:closed", "is:unmerged"]
        case .all: break
        }
        return (parts + ["sort:updated-desc"]).joined(separator: " ")
    }
}
