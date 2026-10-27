import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabPullRequestRepositoryTests {
    @Test func autoMergeSendsTheHeadSHAAndTheOptions() {
        let variables = GlabPullRequestRepository.autoMergeVariables(iid: 21, sha: "abc123", squash: true, removeSourceBranch: false, projectPath: "team/app")

        #expect(variables.map { "\($0.name)=\($0.value)" } == ["path=team/app", "iid=21", "sha=abc123", "squash=true", "remove=false"])
    }

    @Test func createSendsEveryFieldAsRESTFields() {
        let request = NewPullRequest(sourceBranch: "feature/ABC-9", targetBranch: "dev", title: "ABC-9: Login", description: "Ticket: ABC-9", labels: ["feature", "tech"], isDraft: true, removeSourceBranch: true, squash: false)

        let fields = GlabPullRequestRepository.createFields(request).map { "\($0.name)=\($0.value)" }

        #expect(fields == [
            "source_branch=feature/ABC-9",
            "target_branch=dev",
            "title=Draft: ABC-9: Login",
            "description=Ticket: ABC-9",
            "remove_source_branch=true",
            "squash=false",
            "labels=feature,tech",
        ])
    }

    @Test func aValueStartingWithAtIsNotAFileForGlab() {
        let request = NewPullRequest(sourceBranch: "a", targetBranch: "dev", title: "@sam review", description: "@here", labels: [], isDraft: false, removeSourceBranch: false, squash: true)

        let fields = GlabPullRequestRepository.createFields(request).map { "\($0.name)=\($0.value)" }

        #expect(fields.contains("title= @sam review"))
        #expect(fields.contains("description= @here"))
        #expect(fields.contains { $0.hasPrefix("labels=") } == false)
    }

    @Test func aDraftTitleIsNotPrefixedTwice() {
        let request = NewPullRequest(sourceBranch: "a", targetBranch: "dev", title: "Draft: x", description: "", labels: [], isDraft: true, removeSourceBranch: false, squash: false)

        #expect(GlabPullRequestRepository.createFields(request).first { $0.name == "title" }?.value == "Draft: x")
    }

    @Test func theCreatedRequestIsParsed() throws {
        let summary = try GlabCreatedPullRequestParser.summary(from: GlabGraphQLFixture.created)

        #expect(summary.iid == 1404)
        #expect(summary.isDraft)
        #expect(summary.webURL == URL(string: "https://gitlab.example.com/team/app/-/merge_requests/1404"))
        #expect(summary.sourceBranch == "feature/ABC-9")
        #expect(summary.labels == ["feature"])
        #expect(summary.squashOnMerge)
        #expect(summary.removesSourceBranch == true)
        #expect(summary.headSHA == "abc123")
    }

    @Test func aCommentThatStartsWithAnAtSignIsNotReadAsAFile() {
        #expect(GlabPullRequestRepository.commentFields(body: "@sam please check").map(\.value) == [" @sam please check"])
        #expect(GlabPullRequestRepository.commentFields(body: "Looks good").map(\.name) == ["body"])
    }

    @Test func requestChangesIsRefusedOnGitLab() async {
        let repository = GlabPullRequestRepository(client: GlabClient(shell: ShellRunner(recorder: SpyCommandRecorder())))

        await #expect(throws: PullRequestError.self) {
            try await repository.requestChanges(iid: 7, body: "x", repository: .gitLabSample)
        }
    }
}
