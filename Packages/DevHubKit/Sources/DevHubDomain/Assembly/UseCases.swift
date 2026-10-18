import Foundation

package struct UseCases: Sendable {
    package let updateBranch: UpdateBranchUseCase
    package let updateBaseBranch: UpdateBaseBranchUseCase
    package let checkOutRemoteBranch: CheckOutRemoteBranchUseCase
    package let rebaseOnBase: RebaseOnBaseUseCase
    package let switchBranch: SwitchBranchUseCase
    package let createPullRequest: CreatePullRequestUseCase
    package let pushCurrentBranch: PushCurrentBranchUseCase
    package let discardChange: DiscardChangeUseCase
    package let commit: CommitUseCase
    package let removeWorktree: RemoveWorktreeUseCase
    package let cleanFinishedWorktrees: CleanFinishedWorktreesUseCase
    package let createWorktree: CreateWorktreeUseCase
    package let buildAndRun: BuildAndRunUseCase
    package let commandRun: CommandRunUseCase
    package let prepareBuildCheckout: PrepareBuildCheckoutUseCase
    package let launchInstalledApp: LaunchInstalledAppUseCase
    package let relaunchWithMocks: RelaunchWithMocksUseCase
    package let readSimulatorStatus: ReadSimulatorStatusUseCase
    package let checkTools: CheckToolsUseCase

    package init(ports: Ports) {
        updateBranch = UpdateBranchUseCase(git: ports.git)
        updateBaseBranch = UpdateBaseBranchUseCase(git: ports.git)
        checkOutRemoteBranch = CheckOutRemoteBranchUseCase(git: ports.git)
        rebaseOnBase = RebaseOnBaseUseCase(git: ports.git)
        switchBranch = SwitchBranchUseCase(git: ports.git)
        createPullRequest = CreatePullRequestUseCase(git: ports.git, codeHost: ports.codeHost)
        pushCurrentBranch = PushCurrentBranchUseCase(git: ports.git)
        discardChange = DiscardChangeUseCase(changes: ports.git)
        commit = CommitUseCase(git: ports.git)
        let removeWorktree = RemoveWorktreeUseCase(worktrees: ports.worktrees, derivedData: ports.derivedData)
        self.removeWorktree = removeWorktree
        cleanFinishedWorktrees = CleanFinishedWorktreesUseCase(remove: removeWorktree)
        let createWorktree = CreateWorktreeUseCase(worktrees: ports.worktrees)
        self.createWorktree = createWorktree
        buildAndRun = BuildAndRunUseCase(build: ports.build, simulators: ports.simulators, attacher: ports.attacher, mockServer: ports.mockServer)
        commandRun = CommandRunUseCase(scripts: ports.scripts, build: ports.build, simulators: ports.simulators, install: buildAndRun.install)
        prepareBuildCheckout = PrepareBuildCheckoutUseCase(worktrees: ports.worktrees, createWorktree: createWorktree)
        launchInstalledApp = LaunchInstalledAppUseCase(launcher: ports.launcher, simulators: ports.simulators, attacher: ports.attacher, mockServer: ports.mockServer)
        relaunchWithMocks = RelaunchWithMocksUseCase(mockServer: ports.mockServer, simulators: ports.simulators)
        readSimulatorStatus = ReadSimulatorStatusUseCase(scripts: ports.scripts, tools: ports.tools)
        checkTools = CheckToolsUseCase(scripts: ports.scripts, tools: ports.tools)
    }
}
