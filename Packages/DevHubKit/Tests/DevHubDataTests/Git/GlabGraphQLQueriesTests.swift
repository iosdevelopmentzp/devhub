import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GlabGraphQLQueriesTests {
    @Test(arguments: [
        (PullRequestScope.mine, PullRequestStateFilter.opened, "authoredMergeRequests", ["projectPath=team/app", "state=opened"]),
        (.assigned, .merged, "assignedMergeRequests", ["projectPath=team/app", "state=merged"]),
        (.all, .all, "project(fullPath: $path)", ["path=team/app"]),
        (.reviewing, .closed, "project(fullPath: $path)", ["path=team/app", "state=opened"]),
    ])
    func listQueryAndVariables(scope: PullRequestScope, state: PullRequestStateFilter, field: String, variables: [String]) {
        let query = PullRequestQuery(scope: scope, state: state)

        #expect(GlabGraphQLQueries.list(scope).contains(field))
        #expect(GlabGraphQLQueries.list(scope).contains("headPipeline"))
        #expect(GlabGraphQLQueries.list(scope).contains("diffStatsSummary { additions deletions fileCount }"))
        #expect(GlabGraphQLQueries.list(scope).contains("userPermissions { canMerge canApprove }"))
        #expect(GlabGraphQLQueries.listVariables(query, after: nil, projectPath: "team/app").map { "\($0.name)=\($0.value)" } == variables)
    }

    @Test func aCursorReadsTheNextPage() {
        let variables = GlabGraphQLQueries.listVariables(PullRequestQuery(scope: .all, state: .merged), after: "abc", projectPath: "team/app")

        #expect(variables.map { "\($0.name)=\($0.value)" } == ["path=team/app", "state=merged", "after=abc"])
        for scope in PullRequestScope.allCases {
            #expect(GlabGraphQLQueries.list(scope).contains("$after: String"))
            #expect(GlabGraphQLQueries.list(scope).contains("first: 100, after: $after"))
            #expect(GlabGraphQLQueries.list(scope).contains("pageInfo { hasNextPage endCursor }"))
        }
    }

    @Test func detailsReadEveryJobWithItsStatus() {
        #expect(GlabGraphQLQueries.details.contains("headPipeline { duration jobs { nodes { id name status webPath stage { name } } } }"))
    }

    @Test func writesTakeValuesOnlyAsVariables() {
        #expect(GlabGraphQLQueries.setAutoMerge.contains("mergeRequestAccept(input:"))
        #expect(GlabGraphQLQueries.setAutoMerge.contains("strategy: MERGE_WHEN_CHECKS_PASS"))
        #expect(GlabGraphQLQueries.setAutoMerge.contains("sha: $sha"))
        #expect(GlabGraphQLQueries.cancelPipeline.contains("pipelineCancel(input: { id: $id })"))
        #expect(GlabGraphQLQueries.labels.contains("project(fullPath: $path) { labels(first: 100, includeAncestorGroups: true) { nodes { title } } }"))
    }
}
