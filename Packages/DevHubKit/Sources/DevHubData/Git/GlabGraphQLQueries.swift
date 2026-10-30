import Foundation
import DevHubDomain

enum GlabGraphQLQueries {
    private static let fields = """
    count pageInfo { hasNextPage endCursor } nodes { iid title state draft webUrl author { username } sourceBranch targetBranch conflicts \
    detailedMergeStatus userNotesCount updatedAt createdAt mergedAt closedAt mergeUser { username } commitCount \
    diffStatsSummary { additions deletions fileCount } resolvableDiscussionsCount resolvedDiscussionsCount \
    divergedFromTargetBranch squashOnMerge shouldRemoveSourceBranch diffHeadSha autoMergeEnabled \
    userPermissions { canMerge canApprove } \
    headPipeline { status updatedAt duration finishedAt failedJobsCount detailedStatus { detailsPath } } \
    approvedBy { nodes { username } } labels { nodes { title } } assignees { nodes { username } } reviewers { nodes { username } } }
    """

    private static let connection = "(state: $state, sort: UPDATED_DESC, first: 100, after: $after) { \(fields) }"

    static func list(_ scope: PullRequestScope) -> String {
        switch scope {
        case .mine:
            "query($projectPath: String!, $state: MergeRequestState, $after: String) { currentUser { username authoredMergeRequests(projectPath: $projectPath, \(connection.dropFirst()) } }"
        case .assigned:
            "query($projectPath: String!, $state: MergeRequestState, $after: String) { currentUser { username assignedMergeRequests(projectPath: $projectPath, \(connection.dropFirst()) } }"
        case .reviewing, .all:
            "query($path: ID!, $state: MergeRequestState, $after: String) { currentUser { username } project(fullPath: $path) { mergeRequests\(connection) } }"
        }
    }

    static let details = """
    query($path: ID!, $iid: String!) { project(fullPath: $path) { mergeRequest(iid: $iid) { description \
    headPipeline { duration jobs { nodes { id name status webPath stage { name } } } } \
    discussions(first: 100) { nodes { id resolvable resolved notes(first: 100) { nodes { id body system author { username } \
    position { filePath newLine oldLine } } } } } } } }
    """

    static let setDraft = "mutation($path: ID!, $iid: String!, $draft: Boolean!) { mergeRequestSetDraft(input: { projectPath: $path, iid: $iid, draft: $draft }) { errors } }"

    static let setAutoMerge = """
    mutation($path: ID!, $iid: String!, $sha: String!, $squash: Boolean!, $remove: Boolean!) { mergeRequestAccept(input: \
    { projectPath: $path, iid: $iid, sha: $sha, strategy: MERGE_WHEN_CHECKS_PASS, squash: $squash, \
    shouldRemoveSourceBranch: $remove }) { errors } }
    """

    static let labels = "query($path: ID!) { project(fullPath: $path) { labels(first: 100, includeAncestorGroups: true) { nodes { title } } } }"

    static let cancelPipeline = "mutation($id: CiPipelineID!) { pipelineCancel(input: { id: $id }) { errors } }"

    static let toggleResolve = "mutation($id: DiscussionID!, $resolve: Boolean!) { discussionToggleResolve(input: { id: $id, resolve: $resolve }) { errors } }"

    static func listVariables(_ query: PullRequestQuery, after cursor: String?, projectPath: String) -> [(name: String, value: String)] {
        let pathName = query.scope == .mine || query.scope == .assigned ? "projectPath" : "path"
        var variables = [(name: pathName, value: projectPath)]
        let state: PullRequestStateFilter = query.scope == .reviewing ? .opened : query.state
        if state != .all {
            variables.append((name: "state", value: state.rawValue))
        }
        if let cursor {
            variables.append((name: "after", value: cursor))
        }
        return variables
    }
}
