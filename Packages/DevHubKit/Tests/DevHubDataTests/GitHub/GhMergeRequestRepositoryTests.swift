import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhMergeRequestRepositoryTests {
    @Test func listSearchesTheRepositoryAndPassesTheCursor() {
        let variables = GhMergeRequestRepository.listVariables(MergeRequestQuery(scope: .mine, state: .merged), after: "abc", repository: .gitHubSample)

        #expect(variables.map { "\($0.name)=\($0.value)" } == [
            "search=repo:example/app is:pr author:@me is:merged sort:updated-desc",
            "owner=example",
            "name=app",
            "after=abc",
        ])
    }

    @Test func theFirstPageHasNoCursor() {
        let variables = GhMergeRequestRepository.listVariables(MergeRequestQuery(scope: .all, state: .opened), after: nil, repository: .gitHubSample)

        #expect(variables.contains { $0.name == "after" } == false)
    }

    @Test func mergeChoosesTheMethodAndTheBranchDeletion() {
        #expect(GhMergeRequestRepository.mergeArguments(iid: 7, squash: true, removeSourceBranch: true) == ["merge", "7", "--squash", "--delete-branch"])
        #expect(GhMergeRequestRepository.mergeArguments(iid: 7, squash: false, removeSourceBranch: false) == ["merge", "7", "--merge"])
    }

    @Test func createSendsTheDraftAsABoolean() {
        let request = NewMergeRequest(sourceBranch: "feature/ABC-9", targetBranch: "main", title: "@sam ABC-9", description: "Ticket: ABC-9", labels: [], isDraft: true, removeSourceBranch: false, squash: false)

        let fields = GhMergeRequestRepository.createFields(request).flatMap(\.arguments)

        #expect(fields == ["-f", "head=feature/ABC-9", "-f", "base=main", "-f", "title=@sam ABC-9", "-f", "body=Ticket: ABC-9", "-F", "draft=true"])
    }
}
