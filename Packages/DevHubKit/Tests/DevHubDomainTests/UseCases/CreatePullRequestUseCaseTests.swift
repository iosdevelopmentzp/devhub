import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CreatePullRequestUseCaseTests {
    private let request = NewPullRequest(sourceBranch: "feature/a", targetBranch: "dev", title: "A", description: "", labels: [], isDraft: false, removeSourceBranch: true, squash: false)
    private let remote = CodeHost.gitLabSample

    @Test func pushPlanFollowsTheUpstream() {
        #expect(CreatePullRequestUseCase.pushPlan(upstream: nil, ahead: 0, isCurrent: true) == .push(setUpstream: true))
        #expect(CreatePullRequestUseCase.pushPlan(upstream: "origin/a", ahead: 0, isCurrent: true) == .none)
        #expect(CreatePullRequestUseCase.pushPlan(upstream: "origin/a", ahead: 2, isCurrent: true) == .push(setUpstream: false))
        #expect(CreatePullRequestUseCase.pushPlan(upstream: "origin/a", ahead: 2, isCurrent: false) == .push(setUpstream: true))
    }

    @Test func pushesFirstThenCreates() async throws {
        let (ports, spies) = Ports.spies()

        let created = try await CreatePullRequestUseCase(git: ports.git, codeHost: ports.codeHost).execute(request, push: .push(setUpstream: true), remote: "origin", checkoutPath: "/repo", repository: remote)

        #expect(created.sourceBranch == "feature/a")
        #expect(spies.git.calls == [.perform(.push(branch: "feature/a", setUpstream: true, remote: "origin"), path: "/repo")])
        #expect(spies.codeHost.calls == [.create(request, repository: remote)])
    }

    @Test func withoutPushOnlyCreates() async throws {
        let (ports, spies) = Ports.spies()

        _ = try await CreatePullRequestUseCase(git: ports.git, codeHost: ports.codeHost).execute(request, push: .none, remote: "origin", checkoutPath: "/repo", repository: remote)

        #expect(spies.git.calls.isEmpty)
        #expect(spies.codeHost.calls == [.create(request, repository: remote)])
    }

    @Test func aFailedPushCreatesNothing() async {
        let (ports, spies) = Ports.spies()
        spies.git.performError = TestError.scripted("rejected")

        await #expect(throws: TestError.scripted("rejected")) {
            try await CreatePullRequestUseCase(git: ports.git, codeHost: ports.codeHost).execute(request, push: .push(setUpstream: false), remote: "origin", checkoutPath: "/repo", repository: remote)
        }
        #expect(spies.codeHost.calls.isEmpty)
    }
}
