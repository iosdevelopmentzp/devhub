import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhGraphQLQueriesTests {
    @Test(arguments: [
        (PullRequestScope.all, PullRequestStateFilter.opened, "repo:example/app is:pr is:open sort:updated-desc"),
        (.mine, .all, "repo:example/app is:pr author:@me sort:updated-desc"),
        (.assigned, .closed, "repo:example/app is:pr assignee:@me is:closed is:unmerged sort:updated-desc"),
        (.reviewing, .merged, "repo:example/app is:pr review-requested:@me is:open sort:updated-desc"),
    ])
    func searchBuildsTheQualifiers(scope: PullRequestScope, state: PullRequestStateFilter, expected: String) {
        #expect(GhGraphQLQueries.search(PullRequestQuery(scope: scope, state: state), repository: "example/app") == expected)
    }

    @Test func theChecksCarryTheirTitleAndWorkflow() {
        #expect(GhGraphQLQueries.list.contains("... on CheckRun { databaseId name title conclusion status detailsUrl startedAt completedAt checkSuite { workflowRun { databaseId workflow { name } } } }"))
        #expect(GhGraphQLQueries.details.contains("comments(first: 100) { nodes { databaseId body author { login } createdAt } }"))
    }
}
