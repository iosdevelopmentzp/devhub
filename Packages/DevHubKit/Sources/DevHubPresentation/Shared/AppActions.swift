import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AppActions {
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let build: BuildStore
    @ObservationIgnored private let testRuns: TestRunsStore
    @ObservationIgnored private let git: GitStore
    @ObservationIgnored private let pullRequests: PullRequestsStore
    @ObservationIgnored private let newPullRequest: NewPullRequestStore
    @ObservationIgnored private let pullRequestDetails: PullRequestDetailStore
    @ObservationIgnored private let worktrees: WorktreesStore
    @ObservationIgnored private let identity: IdentityStore
    @ObservationIgnored private let logs: LogsStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let workspace: WorkspaceActions
    @ObservationIgnored private let toaster: Toaster

    init(
        navigator: Navigator,
        build: BuildStore,
        testRuns: TestRunsStore,
        git: GitStore,
        pullRequests: PullRequestsStore,
        newPullRequest: NewPullRequestStore,
        pullRequestDetails: PullRequestDetailStore,
        worktrees: WorktreesStore,
        identity: IdentityStore,
        logs: LogsStore,
        session: ProjectSession,
        config: ConfigStore,
        workspace: WorkspaceActions,
        toaster: Toaster
    ) {
        self.navigator = navigator
        self.build = build
        self.testRuns = testRuns
        self.git = git
        self.pullRequests = pullRequests
        self.newPullRequest = newPullRequest
        self.pullRequestDetails = pullRequestDetails
        self.worktrees = worktrees
        self.identity = identity
        self.logs = logs
        self.session = session
        self.config = config
        self.workspace = workspace
        self.toaster = toaster
    }

    // MARK: Built-in actions

    func perform(_ builtin: BuiltinAction) {
        let path = worktrees.mainCheckoutPath
        let branch = worktrees.mainWorktree?.branch
        switch builtin {
        case .buildRun:
            buildAndRun()
        case .runAttach:
            runAndAttach()
        case .build:
            buildOnly()
        case .openEditor:
            openInXcode(path: path)
        case .openFolder:
            openInFinder(path: path)
        case .terminal:
            openTerminal(at: path)
        case .copyBranch:
            guard let branch else { return }
            toaster.copy(branch)
        case .repository:
            openRepository()
        case .newPullRequest:
            guard let branch else { return }
            openNewPullRequest(for: branch)
        case .pullRequests:
            navigator.show(.pullRequests)
        }
    }

    // MARK: Build

    func buildAndRun() {
        navigator.show(.simulators)
        build.run()
    }

    func buildOnly() {
        navigator.show(.simulators)
        build.buildOnly()
    }

    func buildAndRun(worktreeID: Worktree.ID) {
        navigator.show(.simulators)
        build.run(worktreeID: worktreeID)
    }

    func remoteRef(for branch: String) -> String {
        BranchName(branch, remote: worktrees.gitSettings.remote).remoteRef
    }

    func buildAndRun(branch: String) {
        navigator.show(.simulators)
        build.run(branch: branch)
    }

    func buildAndRun(branch: String, on simulatorID: Simulator.ID) {
        build.selectTarget(id: simulatorID)
        buildAndRun(branch: branch)
    }

    func buildAndRun(worktreeID: Worktree.ID, on simulatorID: Simulator.ID) {
        build.selectTarget(id: simulatorID)
        buildAndRun(worktreeID: worktreeID)
    }

    func buildAndRun(on simulatorID: Simulator.ID) {
        build.run(on: simulatorID)
    }

    func runAndAttach() {
        navigator.show(.simulators)
        build.runAndAttach()
    }

    func selectBuildTarget(_ simulatorID: Simulator.ID) {
        build.selectTarget(id: simulatorID)
    }

    func useBuildSource(worktreeID: Worktree.ID?) {
        build.useSource(worktreeID: worktreeID)
    }

    func launchInstalledApp(on simulator: Simulator, attachDebugger: Bool) {
        identity.launchInstalledApp(
            on: simulator,
            profile: build.profile(for: simulator.id),
            attachDebugger: attachDebugger,
            forceCleanInstall: build.state.cleanInstall,
            projectPath: build.sourcePath,
            fallbackAppPath: build.lastBuiltAppPath()
        )
    }

    // MARK: Logs

    func streamLogs(simulatorID: Simulator.ID) {
        navigator.show(.logs)
        logs.stream(on: simulatorID)
    }

    // MARK: Git

    func openBranchOnWeb(_ branch: String) {
        workspace.open(git.branchURL(branch))
    }

    func openNewPullRequest(for branch: String) {
        openWhenLoaded { [git] in git.newPullRequestURL(branch) }
    }

    func openNewPullRequest(for branch: String, target: String) {
        openWhenLoaded { [git] in git.newPullRequestURL(branch, target: target) }
    }

    func openRepository() {
        Task { [weak self] in
            guard let self else { return }
            workspace.open(await git.repositoryWebURL())
        }
    }

    func switchToBranch(_ branch: String) {
        guard git.hasLocalChanges else {
            git.switchTo(branch, plan: .switchOnly)
            return
        }
        navigator.show(.git)
        toaster.show("The checkout has local changes. Use Switch or Stash & Switch in the row of \(branch).")
    }

    func useCheckoutInGitTab(path: String) {
        navigator.show(.git)
        git.selectCheckout(path)
    }

    func createWorktree(branch: String) {
        Task { [weak self] in
            guard let self else { return }
            _ = await worktrees.createAndBootstrap(branch: branch)
        }
    }

    // MARK: GitLab

    func showPullRequests(scope: PullRequestScope) {
        pullRequests.scope = scope
        navigator.show(.pullRequests)
    }

    func open(_ target: TodayTarget) {
        switch target {
        case .pullRequests(let scope): showPullRequests(scope: scope)
        case .pullRequest(let iid): showPullRequest(iid: iid)
        case .worktrees: navigator.show(.worktrees)
        case .simulators: navigator.show(.simulators)
        }
    }

    func open(_ target: ActivityTarget) {
        switch target {
        case .pullRequest(let iid): showPullRequest(iid: iid)
        case .reviewQueue: showPullRequests(scope: .reviewing)
        case .worktree: navigator.show(.worktrees)
        case .build: navigator.show(.simulators)
        }
    }

    func openNotifications() {
        navigator.show(.notifications)
    }

    func showPullRequest(iid: Int) {
        navigator.show(.pullRequests)
        Task { [weak self] in
            guard let self else { return }
            await pullRequests.reveal(iid)
        }
    }

    func startPullRequest(branch: String, origin: NewPullRequestDraft.Origin) {
        Task { [weak self] in
            guard let self else { return }
            await newPullRequest.open(branch: branch, origin: origin)
        }
    }

    func createPullRequest() {
        Task { [weak self] in
            guard let self else { return }
            guard let iid = await newPullRequest.create() else { return }
            showPullRequest(iid: iid)
        }
    }

    func fixThreads(with provider: AIProvider, _ summary: PullRequestSummary) {
        Task { [weak self] in
            guard let self else { return }
            guard let promptPath = await pullRequestDetails.writeReviewPrompt(for: summary) else { return }
            guard let path = await checkoutPath(creatingWorktreeFor: summary.sourceBranch) else { return }
            runAICommand(provider, promptPath: promptPath, at: path, title: "Started \(AISessionRowMapper.toolTitle(for: provider)) on the threads of \(pullRequests.words.reference(summary.iid))")
        }
    }

    func fixTests(with provider: AIProvider, worktreeID: Worktree.ID) {
        Task { [weak self] in
            guard let self else { return }
            guard let promptPath = await testRuns.writeFixPrompt(worktreeID: worktreeID) else { return }
            runAICommand(provider, promptPath: promptPath, at: worktreeID, title: "Started \(AISessionRowMapper.toolTitle(for: provider)) on the failed tests")
        }
    }

    func fixBuild(with provider: AIProvider) {
        Task { [weak self] in
            guard let self else { return }
            guard let promptPath = await build.writeFixPrompt(), let path = build.lastSourcePath else { return }
            runAICommand(provider, promptPath: promptPath, at: path, title: "Started \(AISessionRowMapper.toolTitle(for: provider)) on the build errors")
        }
    }

    private func runAICommand(_ provider: AIProvider, promptPath: String, at path: String, title: String) {
        let template = git.gitSettings.pullRequests.aiCommands[provider] ?? GitSettingsPolicy.aiCommands(nil)[provider] ?? ""
        workspace.runInTerminal(ReviewPromptBuilder.command(promptPath: promptPath, template: template), at: path, title: title)
    }

    private func checkoutPath(creatingWorktreeFor branch: String) async -> String? {
        if let path = worktrees.checkoutPath(forBranch: branch) {
            return path
        }
        guard await worktrees.createAndBootstrap(branch: BranchName(branch, remote: worktrees.gitSettings.remote).remoteRef) else { return nil }
        return worktrees.checkoutPath(forBranch: branch)
    }

    // MARK: Workspace

    func openInFinder(path: String) {
        workspace.openInFinder(path: path)
    }

    func openFile(path: String) {
        workspace.openFile(path: path, line: nil)
    }

    func openFile(path: String, line: Int?) {
        workspace.openFile(path: path, line: line)
    }

    func openSourceFile(path: String, line: Int?, branch: String) {
        let root = worktrees.checkoutPath(forBranch: branch) ?? worktrees.mainCheckoutPath
        workspace.openFile(path: (root as NSString).appendingPathComponent(path), line: line)
    }

    func openInXcode(path: String) {
        workspace.openInXcode(path: path, container: config.config.xcode?.container)
    }

    func openInEditor(path: String, editor: String) {
        workspace.openInEditor(path: path, editor: editor)
    }

    func openInEditor(text: String, name: String) {
        workspace.openInEditor(text: text, name: name)
    }

    func saveText(_ text: String, suggestedName: String) {
        guard let url = FolderPicker.saveFile(suggestedName: suggestedName, prompt: "Save", message: "Choose where to save the text.") else { return }
        workspace.saveText(text, to: url.path)
    }

    func openTerminal(at path: String) {
        workspace.openTerminal(at: path)
    }

    func runInTerminal(_ command: String, at path: String, title: String) {
        workspace.runInTerminal(command, at: path, title: title)
    }

    func startAISession(_ provider: AIProvider, at path: String) {
        workspace.runInTerminal(provider.executable, at: path, title: "Started a \(AISessionRowMapper.title(for: provider)) session")
    }

    func open(_ url: URL?) {
        workspace.open(url)
    }

    // MARK: Navigation

    func openSettings() {
        navigator.show(.settings)
    }

    private func openWhenLoaded(_ url: @escaping () -> URL?) {
        guard git.snapshot == nil else {
            workspace.open(url())
            return
        }
        Task { [weak self] in
            guard let self else { return }
            await git.refresh()
            workspace.open(url())
        }
    }
}
