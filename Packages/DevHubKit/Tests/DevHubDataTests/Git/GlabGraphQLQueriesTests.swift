import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GlabGraphQLQueriesTests {
    @Test(arguments: [
        (MergeRequestScope.mine, MergeRequestStateFilter.opened, "authoredMergeRequests", ["projectPath=team/app", "state=opened"]),
        (.assigned, .merged, "assignedMergeRequests", ["projectPath=team/app", "state=merged"]),
        (.all, .all, "project(fullPath: $path)", ["path=team/app"]),
        (.reviewing, .closed, "project(fullPath: $path)", ["path=team/app", "state=opened"]),
    ])
    func listQueryAndVariables(scope: MergeRequestScope, state: MergeRequestStateFilter, field: String, variables: [String]) {
        let query = MergeRequestQuery(scope: scope, state: state)

        #expect(GlabGraphQLQueries.list(scope).contains(field))
        #expect(GlabGraphQLQueries.list(scope).contains("headPipeline"))
        #expect(GlabGraphQLQueries.list(scope).contains("diffStatsSummary { additions deletions fileCount }"))
        #expect(GlabGraphQLQueries.list(scope).contains("userPermissions { canMerge canApprove }"))
        #expect(GlabGraphQLQueries.listVariables(query, after: nil, projectPath: "team/app").map { "\($0.name)=\($0.value)" } == variables)
    }

    @Test func aCursorReadsTheNextPage() {
        let variables = GlabGraphQLQueries.listVariables(MergeRequestQuery(scope: .all, state: .merged), after: "abc", projectPath: "team/app")

        #expect(variables.map { "\($0.name)=\($0.value)" } == ["path=team/app", "state=merged", "after=abc"])
        for scope in MergeRequestScope.allCases {
            #expect(GlabGraphQLQueries.list(scope).contains("$after: String"))
            #expect(GlabGraphQLQueries.list(scope).contains("first: 100, after: $after"))
            #expect(GlabGraphQLQueries.list(scope).contains("pageInfo { hasNextPage endCursor }"))
        }
    }

    @Test func detailsReadTheFailedJobs() {
        #expect(GlabGraphQLQueries.details.contains("headPipeline { duration jobs(statuses: [FAILED]) { nodes { name webPath stage { name } } } }"))
    }

    @Test func writesTakeValuesOnlyAsVariables() {
        #expect(GlabGraphQLQueries.setAutoMerge.contains("mergeRequestAccept(input:"))
        #expect(GlabGraphQLQueries.setAutoMerge.contains("strategy: MERGE_WHEN_CHECKS_PASS"))
        #expect(GlabGraphQLQueries.setAutoMerge.contains("sha: $sha"))
        #expect(GlabGraphQLQueries.cancelPipeline.contains("pipelineCancel(input: { id: $id })"))
        #expect(GlabGraphQLQueries.labels.contains("project(fullPath: $path) { labels(first: 100, includeAncestorGroups: true) { nodes { title } } }"))
    }
}
