import Foundation
import DevHubDomain
import DevHubUI

@MainActor
package final class PresentationAssembly {
    let commandLog: CommandLog
    let events: AppEvents
    let session: ProjectSession
    let config: ConfigStore
    let navigator: Navigator
    let activity: ActivityLog
    let toaster: Toaster
    let hints: HintCenter
    let output: OutputPanelState
    let layout: WindowLayout
    package let settings: SettingsStore
    let workspace: WorkspaceActions
    let usage: UsageStore
    let worktrees: WorktreesStore
    let git: GitStore
    let changes: GitChangesStore
    let history: CommitHistoryStore
    let codeHostRemote: CodeHostRemote
    let branchPullRequest: BranchPullRequestStore
    let pullRequests: PullRequestsStore
    let openPullRequests: OpenPullRequestsStore
    let newPullRequest: NewPullRequestStore
    let pullRequestDetails: PullRequestDetailStore
    let simulators: SimulatorsStore
    let identity: IdentityStore
    let build: BuildStore
    let configActions: ConfigActionsStore
    let logs: LogsStore
    let mockSets: MockSetsStore
    let mockServer: MockServerStore
    let network: NetworkStore
    let messaging: MessagingStore
    let claudeSessions: ClaudeSessionsStore
    let appActions: AppActions

    package init(
        ports: Ports,
        useCases: UseCases,
        store: any KeyValueStore,
        commandLog: CommandLog,
        projects: [Project],
        selectedProjectID: Project.ID?,
        settings initialSettings: AppSettings,
        recentEvents: [ActivityEvent]
    ) {
        self.commandLog = commandLog
        events = AppEvents()
        session = ProjectSession(projects: projects, selectedProjectID: selectedProjectID, store: store, events: events, detector: ports.projectDetector)
        config = ConfigStore(repository: ports.config, session: session, events: events)
        navigator = Navigator(store: store)
        activity = ActivityLog(events: recentEvents)
        toaster = Toaster(write: PasteboardWriter.write)
        hints = HintCenter()
        output = OutputPanelState(store: store, events: events)
        layout = WindowLayout(store: store)
        settings = SettingsStore(values: initialSettings, store: store)
        workspace = WorkspaceActions(settings: settings, activity: activity, opener: ports.opener)
        usage = UsageStore(repository: ports.usage)
        worktrees = WorktreesStore(
            repository: ports.worktrees,
            derivedData: ports.derivedData,
            removeWorktree: useCases.removeWorktree,
            cleanFinishedWorktrees: useCases.cleanFinishedWorktrees,
            createWorktree: useCases.createWorktree,
            session: session,
            config: config,
            activity: activity,
            events: events
        )
        git = GitStore(
            repository: ports.git,
            updateBranch: useCases.updateBranch,
            updateBaseBranch: useCases.updateBaseBranch,
            checkOutRemoteBranch: useCases.checkOutRemoteBranch,
            rebaseOnBaseBranch: useCases.rebaseOnBase,
            switchBranch: useCases.switchBranch,
            pushCurrentBranch: useCases.pushCurrentBranch,
            worktrees: worktrees,
            activity: activity,
            events: events,
            store: store
        )
        changes = GitChangesStore(
            repository: ports.changes,
            git: ports.git,
            discardChange: useCases.discardChange,
            commitChanges: useCases.commit,
            checkout: git,
            activity: activity,
            events: events
        )
        history = CommitHistoryStore(repository: ports.changes, checkout: git, activity: activity, events: events, store: store)
        branchPullRequest = BranchPullRequestStore(repository: ports.codeHost, checkout: git, events: events)
        codeHostRemote = CodeHostRemote(git: ports.git, worktrees: worktrees, events: events)
        pullRequests = PullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, events: events, store: store)
        openPullRequests = OpenPullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, events: events)
        pullRequestDetails = PullRequestDetailStore(repository: ports.codeHost, remote: codeHostRemote, prompts: ports.reviewPrompts, activity: activity, events: events)
        newPullRequest = NewPullRequestStore(
            git: ports.git,
            codeHost: ports.codeHost,
            createPullRequest: useCases.createPullRequest,
            checkout: git,
            remote: codeHostRemote,
            activity: activity,
            events: events
        )
        simulators = SimulatorsStore(repository: ports.simulators, activity: activity, events: events, store: store)
        identity = IdentityStore(
            repository: ports.identity,
            launchInstalledApp: useCases.launchInstalledApp,
            session: session,
            simulators: simulators,
            attacher: ports.attacher,
            activity: activity,
            events: events,
            store: store
        )
        build = BuildStore(
            repository: ports.build,
            buildAndRun: useCases.buildAndRun,
            prepareCheckout: useCases.prepareBuildCheckout,
            config: config,
            session: session,
            worktrees: worktrees,
            simulators: simulators,
            identity: identity,
            attacher: ports.attacher,
            activity: activity,
            events: events,
            store: store
        )
        configActions = ConfigActionsStore(
            config: config,
            scripts: ports.scripts,
            tools: ports.tools,
            session: session,
            checkout: git,
            worktrees: worktrees,
            codeHosts: codeHostRemote,
            build: build,
            workspace: workspace,
            toaster: toaster,
            activity: activity,
            events: events,
            store: store,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            home: FileManager.default.homeDirectoryForCurrentUser.path
        )
        logs = LogsStore(repository: ports.logs, session: session, store: store)
        mockSets = MockSetsStore(repository: ports.mockSets, session: session, activity: activity, events: events)
        mockServer = MockServerStore(
            relaunch: useCases.relaunchWithMocks,
            server: ports.mockServer,
            session: session,
            simulators: simulators,
            identity: identity,
            sets: mockSets,
            activity: activity,
            events: events,
            store: store
        )
        network = NetworkStore(session: session, simulators: simulators, mockTraffic: mockServer, events: events, store: store)
        messaging = MessagingStore(repository: ports.messaging, session: session, activity: activity, events: events, store: store)
        claudeSessions = ClaudeSessionsStore(repository: ports.claudeSessions, session: session, store: store)
        appActions = AppActions(
            navigator: navigator,
            build: build,
            git: git,
            pullRequests: pullRequests,
            newPullRequest: newPullRequest,
            pullRequestDetails: pullRequestDetails,
            worktrees: worktrees,
            identity: identity,
            logs: logs,
            session: session,
            workspace: workspace,
            toaster: toaster
        )
    }
}
