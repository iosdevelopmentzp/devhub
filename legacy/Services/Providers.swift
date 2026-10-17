import Foundation

nonisolated struct Providers: Sendable {
    let git: GitRepositoryProviding
    let hosting: PullRequestProviding
    let worktrees: WorktreeProviding
    let build: BuildProviding
    let debugger: DebuggerAttaching
    let simulators: SimulatorProviding
    let logs: AppLogProviding
    let ai: AISessionProviding
    let usage: UsageProviding
    let config: ConfigProviding
    let projects: ProjectDetecting
    let tools: ToolLocating
    let workspace: WorkspaceActing

    static let mock = Providers(
        git: MockGitRepositoryProvider(),
        hosting: MockPullRequestProvider(),
        worktrees: MockWorktreeProvider(),
        build: MockBuildProvider(),
        debugger: MockDebuggerAttacher(),
        simulators: MockSimulatorProvider(),
        logs: MockAppLogProvider(),
        ai: MockAISessionProvider(),
        usage: MockUsageProvider(),
        config: MockConfigProvider(),
        projects: MockProjectDetector(),
        tools: MockToolLocator(),
        workspace: MockWorkspaceActions()
    )

    static let live = Providers(
        git: LiveGitRepositoryProvider(shell: .shared),
        hosting: LivePullRequestProvider(shell: .shared, tools: LiveToolLocator()),
        worktrees: LiveWorktreeProvider(shell: .shared),
        build: LiveBuildProvider(shell: .shared, home: NSHomeDirectory()),
        debugger: LiveDebuggerAttacher(shell: .shared),
        simulators: LiveSimulatorProvider(shell: .shared, home: NSHomeDirectory()),
        logs: LiveAppLogProvider(shell: .shared),
        ai: LiveAISessionProvider(home: NSHomeDirectory()),
        usage: LiveUsageProvider(shell: .shared, home: NSHomeDirectory()),
        config: LiveConfigProvider(home: NSHomeDirectory()),
        projects: LiveProjectDetector(shell: .shared),
        tools: LiveToolLocator(),
        workspace: LiveWorkspaceActions(shell: .shared)
    )
}
