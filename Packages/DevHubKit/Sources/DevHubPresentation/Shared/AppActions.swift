import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class AppActions {
    @ObservationIgnored private let navigator: Navigator
    @ObservationIgnored private let build: BuildStore
    @ObservationIgnored private let git: GitStore
    @ObservationIgnored private let gitLab: GitLabStore
    @ObservationIgnored private let newMergeRequest: NewMergeRequestStore
    @ObservationIgnored private let mergeRequestDetails: MergeRequestDetailStore
    @ObservationIgnored private let worktrees: WorktreesStore
    @ObservationIgnored private let identity: IdentityStore
    @ObservationIgnored private let logs: LogsStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let workspace: WorkspaceActions
    @ObservationIgnored private let toaster: Toaster

    init(
        navigator: Navigator,
        build: BuildStore,
        git: GitStore,
        gitLab: GitLabStore,
        newMergeRequest: NewMergeRequestStore,
        mergeRequestDetails: MergeRequestDetailStore,
        worktrees: WorktreesStore,
        identity: IdentityStore,
        logs: LogsStore,
        session: ProjectSession,
        workspace: WorkspaceActions,
        toaster: Toaster
    ) {
        self.navigator = navigator
        self.build = build
        self.git = git
        self.gitLab = gitLab
        self.newMergeRequest = newMergeRequest
        self.mergeRequestDetails = mergeRequestDetails
        self.worktrees = worktrees
        self.identity = identity
        self.logs = logs
        self.session = session
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
            openNewMergeRequest(for: branch)
        }
    }

    // MARK: Build

    func buildAndRun() {
        navigator.show(.simulators)
        build.run()
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

    func openNewMergeRequest(for branch: String) {
        openWhenLoaded { [git] in git.newMergeRequestURL(branch) }
    }

    func openNewMergeRequest(for branch: String, target: String) {
        openWhenLoaded { [git] in git.newMergeRequestURL(branch, target: target) }
    }

    func openRepository() {
        Task { [weak self] in
            guard let self else { return }
            workspace.open(await git.repositoryWebURL())
        }
    }

    func switchToBranch(_ branch: String) {
        git.switchTo(branch, plan: .switchOnly)
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

    func showMergeRequest(iid: Int) {
        navigator.show(.gitlab)
        Task { [weak self] in
            guard let self else { return }
            await gitLab.reveal(iid)
        }
    }

    func startMergeRequest(branch: String, origin: NewMergeRequestDraft.Origin) {
        Task { [weak self] in
            guard let self else { return }
            await newMergeRequest.open(branch: branch, origin: origin)
        }
    }

    func createMergeRequest() {
        Task { [weak self] in
            guard let self else { return }
            guard let iid = await newMergeRequest.create() else { return }
            showMergeRequest(iid: iid)
        }
    }

    func fixThreadsWithClaude(_ summary: MergeRequestSummary) {
        Task { [weak self] in
            guard let self else { return }
            guard let promptPath = await mergeRequestDetails.writeReviewPrompt(for: summary) else { return }
            guard let path = await checkoutPath(creatingWorktreeFor: summary.sourceBranch) else { return }
            workspace.runInTerminal(ReviewPromptBuilder.command(promptPath: promptPath), at: path, title: "Started Claude on the threads of !\(summary.iid)")
        }
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

    func openSourceFile(path: String, line: Int?, branch: String) {
        let root = worktrees.checkoutPath(forBranch: branch) ?? worktrees.mainCheckoutPath
        workspace.openFile(path: (root as NSString).appendingPathComponent(path), line: line)
    }

    func openInXcode(path: String) {
        workspace.openInXcode(path: path)
    }

    func openInEditor(path: String, editor: String) {
        workspace.openInEditor(path: path, editor: editor)
    }

    func openTerminal(at path: String) {
        workspace.openTerminal(at: path)
    }

    func runInTerminal(_ command: String, at path: String, title: String) {
        workspace.runInTerminal(command, at: path, title: title)
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
