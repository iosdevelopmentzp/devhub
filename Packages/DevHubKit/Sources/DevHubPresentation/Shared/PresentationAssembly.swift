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
    let operations: OperationLog
    let toaster: Toaster
    let notifier: Notifier
    let doctor: DoctorStore
    let xcodes: XcodeSelectionStore
    let keepAwake: KeepAwakeStore
    let hints: HintCenter
    let output: OutputPanelState
    let layout: WindowLayout
    package let settings: SettingsStore
    let workspace: WorkspaceActions
    let usage: UsageStore
    let worktrees: WorktreesStore
    let git: GitStore
    let branchMarks: BranchMarksStore
    let scriptList: ScriptListStore
    let changes: GitChangesStore
    let history: CommitHistoryStore
    let codeHostRemote: CodeHostRemote
    let ciProjects: CIProjectResolver
    let ciHistory: CIWorkflowHistory
    let ciAutoRerun: CIAutoRerunStore
    let pullRequestHiddenFiles: PullRequestHiddenFiles
    let branchPullRequest: BranchPullRequestStore
    let pullRequests: PullRequestsStore
    let openPullRequests: OpenPullRequestsStore
    let inbox: InboxStore
    let newPullRequest: NewPullRequestStore
    let pullRequestDetails: PullRequestDetailStore
    let simulators: SimulatorsStore
    let identity: IdentityStore
    let build: BuildStore
    let testRuns: TestRunsStore
    let simulatorStatuses: SimulatorStatusStore
    let configActions: ConfigActionsStore
    let logs: LogsStore
    let mockSets: MockSetsStore
    let mockServer: MockServerStore
    let network: NetworkStore
    let messaging: MessagingStore
    let simulatorQA: SimulatorQAStore
    let aiSessions: AISessionsStore
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
        activity = ActivityLog(events: recentEvents, store: store)
        operations = OperationLog()
        toaster = Toaster(write: PasteboardWriter.write)
        hints = HintCenter()
        output = OutputPanelState(store: store, events: events)
        layout = WindowLayout(store: store)
        settings = SettingsStore(values: initialSettings, store: store)
        workspace = WorkspaceActions(settings: settings, activity: activity, opener: ports.opener, files: ports.textFiles)
        notifier = Notifier(repository: ports.notifications, settings: settings, activity: activity)
        doctor = DoctorStore(checkTools: useCases.checkTools, attacher: ports.attacher)
        xcodes = XcodeSelectionStore(repository: ports.xcodes, environment: ports.toolEnvironment, session: session, config: config, activity: activity, events: events)
        keepAwake = KeepAwakeStore(preventer: ports.sleep, activity: activity)
        usage = UsageStore(repository: ports.usage, copilotRepository: ports.copilotUsage)
        usage.providers = initialSettings.usageProviders
        settings.onUsageProvidersChange = { [usage] in usage.providers = $0 }
        worktrees = WorktreesStore(
            repository: ports.worktrees,
            derivedData: ports.derivedData,
            removeWorktree: useCases.removeWorktree,
            cleanFinishedWorktrees: useCases.cleanFinishedWorktrees,
            createWorktree: useCases.createWorktree,
            session: session,
            config: config,
            activity: activity,
            operations: operations,
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
            operations: operations,
            events: events,
            store: store
        )
        branchMarks = BranchMarksStore(session: session, events: events, store: store)
        scriptList = ScriptListStore(session: session, events: events, store: store)
        changes = GitChangesStore(
            repository: ports.changes,
            git: ports.git,
            discardChange: useCases.discardChange,
            commitChanges: useCases.commit,
            checkout: git,
            activity: activity,
            operations: operations,
            events: events
        )
        history = CommitHistoryStore(repository: ports.changes, checkout: git, activity: activity, events: events, store: store)
        branchPullRequest = BranchPullRequestStore(repository: ports.codeHost, checkout: git, events: events)
        codeHostRemote = CodeHostRemote(git: ports.git, worktrees: worktrees, events: events)
        ciProjects = CIProjectResolver(config: config, worktrees: worktrees, remote: codeHostRemote, tools: ports.tools, events: events)
        ciHistory = CIWorkflowHistory(session: session, events: events, store: store)
        pullRequestHiddenFiles = PullRequestHiddenFiles(session: session, events: events, store: store)
        pullRequests = PullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, operations: operations, events: events, store: store)
        openPullRequests = OpenPullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, session: session, activity: activity, notifier: notifier, events: events, store: store)
        inbox = InboxStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, notifier: notifier, events: events)
        ciAutoRerun = CIAutoRerunStore(
            repository: ports.codeHost,
            ci: ports.ci,
            projects: ciProjects,
            history: ciHistory,
            remote: codeHostRemote,
            session: session,
            activity: activity,
            notifier: notifier,
            events: events,
            store: store
        )
        pullRequestDetails = PullRequestDetailStore(
            repository: ports.codeHost,
            ci: ports.ci,
            remote: codeHostRemote,
            prompts: ports.reviewPrompts,
            projects: ciProjects,
            history: ciHistory,
            autoRerun: ciAutoRerun,
            hiddenFiles: pullRequestHiddenFiles,
            activity: activity,
            operations: operations,
            events: events
        )
        newPullRequest = NewPullRequestStore(
            git: ports.git,
            codeHost: ports.codeHost,
            createPullRequest: useCases.createPullRequest,
            checkout: git,
            remote: codeHostRemote,
            activity: activity,
            events: events
        )
        simulators = SimulatorsStore(repository: ports.simulators, activity: activity, operations: operations, events: events, store: store)
        identity = IdentityStore(
            repository: ports.launcher,
            launchInstalledApp: useCases.launchInstalledApp,
            session: session,
            config: config,
            simulators: simulators,
            attacher: ports.attacher,
            activity: activity,
            events: events,
            store: store
        )
        build = BuildStore(
            repository: ports.build,
            buildAndRun: useCases.buildAndRun,
            commandRun: useCases.commandRun,
            prepareCheckout: useCases.prepareBuildCheckout,
            config: config,
            session: session,
            worktrees: worktrees,
            simulators: simulators,
            identity: identity,
            attacher: ports.attacher,
            activity: activity,
            notifier: notifier,
            events: events,
            store: store,
            prompts: ports.reviewPrompts
        )
        testRuns = TestRunsStore(runTests: useCases.runTests, build: build, worktrees: worktrees, config: config, activity: activity, notifier: notifier, events: events, prompts: ports.reviewPrompts)
        simulatorStatuses = SimulatorStatusStore(
            readStatus: useCases.readSimulatorStatus,
            config: config,
            session: session,
            simulators: simulators,
            build: build,
            codeHosts: codeHostRemote,
            launcher: ports.launcher,
            events: events,
            settleDelay: .seconds(3)
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
            launcher: ports.launcher,
            workspace: workspace,
            toaster: toaster,
            activity: activity,
            operations: operations,
            notifier: notifier,
            events: events,
            store: store,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            home: FileManager.default.homeDirectoryForCurrentUser.path
        )
        logs = LogsStore(repository: ports.logs, session: session, config: config, simulators: simulators, identity: identity, activity: activity, store: store)
        mockSets = MockSetsStore(repository: ports.mockSets, session: session, config: config, activity: activity, events: events)
        mockServer = MockServerStore(
            relaunch: useCases.relaunchWithMocks,
            server: ports.mockServer,
            session: session,
            simulators: simulators,
            identity: identity,
            build: build,
            config: config,
            sets: mockSets,
            activity: activity,
            events: events,
            store: store
        )
        network = NetworkStore(session: session, simulators: simulators, mockTraffic: mockServer, events: events, store: store)
        messaging = MessagingStore(repository: ports.messaging, session: session, identity: identity, activity: activity, operations: operations, events: events, store: store)
        simulatorQA = SimulatorQAStore(repository: ports.simulatorSettings, activity: activity, screenshotFolder: "~/Desktop", now: { .now })
        aiSessions = AISessionsStore(repository: ports.aiSessions, session: session, worktrees: worktrees, store: store)
        appActions = AppActions(
            navigator: navigator,
            build: build,
            testRuns: testRuns,
            git: git,
            pullRequests: pullRequests,
            openPullRequests: openPullRequests,
            inbox: inbox,
            newPullRequest: newPullRequest,
            pullRequestDetails: pullRequestDetails,
            worktrees: worktrees,
            identity: identity,
            logs: logs,
            session: session,
            config: config,
            workspace: workspace,
            toaster: toaster
        )
    }
}
