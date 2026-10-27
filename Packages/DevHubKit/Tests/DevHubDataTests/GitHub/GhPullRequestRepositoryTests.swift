import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhPullRequestRepositoryTests {
    @Test func listSearchesTheRepositoryAndPassesTheCursor() {
        let variables = GhPullRequestRepository.listVariables(PullRequestQuery(scope: .mine, state: .merged), after: "abc", repository: .gitHubSample)

        #expect(variables.map { "\($0.name)=\($0.value)" } == [
            "search=repo:example/app is:pr author:@me is:merged sort:updated-desc",
            "owner=example",
            "name=app",
            "after=abc",
        ])
    }

    @Test func theFirstPageHasNoCursor() {
        let variables = GhPullRequestRepository.listVariables(PullRequestQuery(scope: .all, state: .opened), after: nil, repository: .gitHubSample)

        #expect(variables.contains { $0.name == "after" } == false)
    }

    @Test func mergeChoosesTheMethodAndTheBranchDeletion() {
        #expect(GhPullRequestRepository.mergeArguments(iid: 7, squash: true, removeSourceBranch: true) == ["merge", "7", "--squash", "--delete-branch"])
        #expect(GhPullRequestRepository.mergeArguments(iid: 7, squash: false, removeSourceBranch: false) == ["merge", "7", "--merge"])
    }

    @Test func createSendsTheDraftAsABoolean() {
        let request = NewPullRequest(sourceBranch: "feature/ABC-9", targetBranch: "main", title: "@sam ABC-9", description: "Ticket: ABC-9", labels: [], isDraft: true, removeSourceBranch: false, squash: false)

        let fields = GhPullRequestRepository.createFields(request).flatMap(\.arguments)

        #expect(fields == ["-f", "head=feature/ABC-9", "-f", "base=main", "-f", "title=@sam ABC-9", "-f", "body=Ticket: ABC-9", "-F", "draft=true"])
    }

    @Test func commentAndRequestChangesUseTheBodyFlag() {
        #expect(GhPullRequestRepository.commentArguments(iid: 7, body: "Looks good") == ["comment", "7", "--body", "Looks good"])
        #expect(GhPullRequestRepository.requestChangesArguments(iid: 7, body: "Fix the test") == ["review", "7", "--request-changes", "--body", "Fix the test"])
    }

    @Test func aLineCommentNamesTheSideOfTheLine() throws {
        let added = PullRequestLineComment(path: "App/a.swift", oldPath: "Old/a.swift", newLine: 12, oldLine: nil, body: "Why?", headSHA: "abc")
        let removed = PullRequestLineComment(path: "App/a.swift", oldPath: "Old/a.swift", newLine: nil, oldLine: 9, body: "Why?", headSHA: "abc")

        #expect(try GhPullRequestRepository.lineCommentFields(added).flatMap(\.arguments) == ["-f", "body=Why?", "-f", "commit_id=abc", "-f", "path=App/a.swift", "-F", "line=12", "-f", "side=RIGHT"])
        #expect(try GhPullRequestRepository.lineCommentFields(removed).flatMap(\.arguments) == ["-f", "body=Why?", "-f", "commit_id=abc", "-f", "path=Old/a.swift", "-F", "line=9", "-f", "side=LEFT"])
    }

    @Test func aLineCommentNeedsTheHeadCommit() {
        let comment = PullRequestLineComment(path: "a.swift", oldPath: "a.swift", newLine: 1, oldLine: nil, body: "x", headSHA: nil)

        #expect(throws: PullRequestError.self) {
            try GhPullRequestRepository.lineCommentFields(comment)
        }
    }
}
