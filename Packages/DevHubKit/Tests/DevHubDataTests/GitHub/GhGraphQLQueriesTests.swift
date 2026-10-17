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
}
