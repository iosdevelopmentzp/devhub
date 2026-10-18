import DevHubDomain
import DevHubMocks
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AppActionsTests {
    @Test func showPullRequestOpensTheGitLabTabAndRevealsIt() async throws {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.showPullRequest(iid: 1839)

        #expect(assembly.navigator.selection == .feature(.pullRequests))
        try await waitUntil { assembly.pullRequests.expandedID == 1839 }
        #expect(assembly.pullRequests.revealedID == 1839)
    }

    @Test func useCheckoutInGitTabSelectsTheWorktree() {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.useCheckoutInGitTab(path: "/tmp/worktree")

        #expect(assembly.navigator.selection == .feature(.git))
        #expect(assembly.git.selectedCheckoutPath == "/tmp/worktree")
    }

    @Test func fixThreadsWritesThePromptAndStartsClaudeInTheWorktree() async throws {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)
        let thread = ReviewThread(id: "t1", noteID: 1, author: "lee", body: "Rename", filePath: "a.swift", line: 3, isOnOldLine: false, replies: [])
        spies.git.webURLResult = URL(string: "https://gitlab.example.com/team/app")
        spies.codeHost.detailsResult = .success(PullRequestDetails(description: "", threads: [thread]))
        spies.reviewPrompts.saveResult = .success("/tmp/prompts/mr-21.md")
        spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.feature])
        await assembly.worktrees.refresh()

        assembly.appActions.fixThreadsWithClaude(PullRequestSummaryFixture.open)

        let command = "claude \"$(cat '/tmp/prompts/mr-21.md')\""
        try await waitUntil {
            spies.opener.calls.contains(.runInTerminal(AppSettings().terminal, path: WorktreeSample.feature.path, command: command))
        }
        #expect(spies.worktrees.calls.contains { if case .create = $0 { true } else { false } } == false)
    }

    @Test func fixThreadsWithoutThreadsStartsNothing() async throws {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)
        spies.git.webURLResult = URL(string: "https://gitlab.example.com/team/app")

        assembly.appActions.fixThreadsWithClaude(PullRequestSummaryFixture.open)

        try await waitUntil { assembly.activity.events.first?.title == "!21 has no open threads" }
        #expect(spies.opener.calls.isEmpty)
    }

    private func spyAssembly(_ ports: Ports) -> PresentationAssembly {
        PresentationAssembly(
            ports: ports,
            useCases: UseCases(ports: ports),
            store: InMemoryKeyValueStore(),
            commandLog: CommandLog(),
            projects: [ProjectSample.app],
            selectedProjectID: nil,
            settings: AppSettings(),
            recentEvents: []
        )
    }
}
