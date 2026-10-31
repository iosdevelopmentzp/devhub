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

        assembly.appActions.fixThreads(with: .claude, PullRequestSummaryFixture.open)

        let command = "claude \"$(cat '/tmp/prompts/mr-21.md')\""
        try await waitUntil {
            spies.opener.calls.contains(.runInTerminal(AppSettings().terminal, path: WorktreeSample.feature.path, command: command))
        }

        assembly.appActions.fixThreads(with: .copilot, PullRequestSummaryFixture.open)

        let copilot = "copilot -i \"$(cat '/tmp/prompts/mr-21.md')\""
        try await waitUntil {
            spies.opener.calls.contains(.runInTerminal(AppSettings().terminal, path: WorktreeSample.feature.path, command: copilot))
        }
        #expect(spies.worktrees.calls.contains { if case .create = $0 { true } else { false } } == false)
    }

    @Test func fixThreadsWithoutThreadsStartsNothing() async throws {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)
        spies.git.webURLResult = URL(string: "https://gitlab.example.com/team/app")

        assembly.appActions.fixThreads(with: .claude, PullRequestSummaryFixture.open)

        try await waitUntil { assembly.activity.events.first?.title == "!21 has no open threads" }
        #expect(spies.opener.calls.isEmpty)
    }

    @Test func fixBuildWithoutErrorsStartsNothing() async throws {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)

        assembly.appActions.fixBuild(with: .copilot)

        try await waitUntil { assembly.activity.events.first?.title == "Nothing to fix" }
        #expect(spies.opener.calls.isEmpty)
        #expect(spies.reviewPrompts.calls.isEmpty)
    }

    @Test func fixTestsWithoutARunStartsNothing() async {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)

        assembly.appActions.fixTests(with: .claude, worktreeID: "/tmp/none")
        await Task.yield()

        #expect(spies.opener.calls.isEmpty)
        #expect(spies.reviewPrompts.calls.isEmpty)
    }

    @Test func startAISessionRunsTheToolInTheFolder() async throws {
        let (ports, spies) = Ports.spies()
        let assembly = spyAssembly(ports)

        assembly.appActions.startAISession(.copilot, at: "/tmp/DevHubTests/wt")

        try await waitUntil { spies.opener.calls == [.runInTerminal(AppSettings().terminal, path: "/tmp/DevHubTests/wt", command: "copilot")] }
        try await waitUntil { assembly.activity.events.first?.title == "Started a Copilot session" }
    }

    @Test func toggleWatchFlipsTheWatchAndShowsAToast() {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.toggleWatch(iid: 12)

        #expect(assembly.openPullRequests.watchedIDs == [12])
        #expect(assembly.toaster.text?.hasPrefix("Watching ") == true)

        assembly.appActions.toggleWatch(iid: 12)

        #expect(assembly.openPullRequests.watchedIDs.isEmpty)
        #expect(assembly.toaster.text?.hasPrefix("Stopped watching ") == true)
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

    @Test func activityTargetsOpenTheirPlace() async throws {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.open(ActivityTarget.reviewQueue)
        #expect(assembly.navigator.selection == .feature(.pullRequests))
        #expect(assembly.pullRequests.scope == .reviewing)

        assembly.appActions.open(ActivityTarget.worktree(path: "/w"))
        #expect(assembly.navigator.selection == .feature(.worktrees))

        assembly.appActions.open(ActivityTarget.build)
        #expect(assembly.navigator.selection == .feature(.simulators))

        assembly.appActions.open(ActivityTarget.pullRequest(iid: 1839))
        #expect(assembly.navigator.selection == .feature(.pullRequests))
        try await waitUntil { assembly.pullRequests.revealedID == 1839 }
    }

    @Test func openNotificationsShowsTheScreen() {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.openNotifications()

        #expect(assembly.navigator.selection == .feature(.notifications))
    }

    @Test func todayTargetsOpenTheirPlace() {
        let assembly = PresentationAssembly.preview()

        assembly.appActions.open(.pullRequests(.reviewing))
        #expect(assembly.navigator.selection == .feature(.pullRequests))
        #expect(assembly.pullRequests.scope == .reviewing)

        assembly.appActions.open(.worktrees)
        #expect(assembly.navigator.selection == .feature(.worktrees))

        assembly.appActions.open(.simulators)
        #expect(assembly.navigator.selection == .feature(.simulators))
    }
}
