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
    let pullRequestReviews: PullRequestReviewMemory
    let branchPullRequest: BranchPullRequestStore
    let ciBranchRuns: CIBranchRunsStore
    let pullRequests: PullRequestsStore
    let openPullRequests: OpenPullRequestsStore
    let ciWatch: CIWatchStore
    let ciDiagnostics: CIDiagnosticsStore
    let inbox: InboxStore
    let newPullRequest: NewPullRequestStore
    let pullRequestDetails: PullRequestDetailStore
    let pullRequestPeople: PullRequestPeopleStore
    let aiText: AITextStore
    let simulators: SimulatorsStore
    let identity: IdentityStore
    let build: BuildStore
    let testRuns: TestRunsStore
    let simulatorStatuses: SimulatorStatusStore
    let configActions: ConfigActionsStore
    let logs: LogsStore
    let crashes: CrashReportsStore
    let mockSets: MockSetsStore
    let mockServer: MockServerStore
    let network: NetworkStore
    let messaging: MessagingStore
    let simulatorQA: SimulatorQAStore
    let media: MediaStore
    let appData: AppDataStore
    let diskCleanup: DiskCleanupStore
    let videoCompression: VideoCompressionStore
    let tickets: TicketsStore
    let aiSessions: AISessionsStore
    let updates: UpdateStore
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
        navigator = Navigator(store: store, customTabs: config)
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
        ciBranchRuns = CIBranchRunsStore(ci: ports.ci, projects: ciProjects, checkout: git, activity: activity, operations: operations, notifier: notifier, events: events, basePollInterval: .seconds(300))
        pullRequestHiddenFiles = PullRequestHiddenFiles(session: session, events: events, store: store)
        pullRequestReviews = PullRequestReviewMemory(session: session, settings: settings, events: events, store: store, now: { .now })
        openPullRequests = OpenPullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, session: session, checkout: git, activity: activity, notifier: notifier, events: events, store: store)
        pullRequests = PullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, openRequests: openPullRequests, activity: activity, operations: operations, events: events, store: store)
        pullRequestPeople = PullRequestPeopleStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, operations: operations, events: events)
        aiText = AITextStore(
            repository: ports.aiText,
            changes: ports.changes,
            git: ports.git,
            checkout: git,
            remote: codeHostRemote,
            settings: settings,
            operations: operations,
            activity: activity,
            events: events
        )
        ciWatch = CIWatchStore(
            repository: ports.codeHost,
            ci: ports.ci,
            projects: ciProjects,
            remote: codeHostRemote,
            openRequests: openPullRequests,
            session: session,
            activity: activity,
            notifier: notifier,
            events: events,
            store: store,
            pollInterval: .seconds(60)
        )
        ciDiagnostics = CIDiagnosticsStore(
            ci: ports.ci,
            words: ports.redactionWords,
            files: ports.textFiles,
            commandLog: commandLog,
            config: config,
            projects: ciProjects,
            checkout: git,
            openRequests: openPullRequests,
            activity: activity,
            toaster: toaster,
            home: FileManager.default.homeDirectoryForCurrentUser.path,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            now: { .now },
            chooseFile: { FolderPicker.saveFile(suggestedName: $0, prompt: "Save", message: "A text file for a bug report. Project names, branches and logins are replaced.") }
        )
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
            reviews: pullRequestReviews,
            activity: activity,
            operations: operations,
            ciPollInterval: .seconds(30),
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
        simulators = SimulatorsStore(repository: ports.simulators, devices: ports.devices, activity: activity, operations: operations, events: events, store: store)
        identity = IdentityStore(
            repository: ports.launcher,
            devices: ports.devices,
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
        identity.use(build: build)
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
            simulators: simulators,
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
        crashes = CrashReportsStore(repository: ports.crashes, prompts: ports.reviewPrompts, activity: activity, notifier: notifier, events: events)
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
        simulatorQA = SimulatorQAStore(repository: ports.simulatorSettings, media: ports.media, store: store, activity: activity, operations: operations, screenshotFolder: "~/Desktop", now: { .now })
        media = MediaStore(repository: ports.media, operations: operations, activity: activity)
        appData = AppDataStore(repository: ports.appData, operations: operations, activity: activity, events: events)
        diskCleanup = DiskCleanupStore(repository: ports.diskCleanup, operations: operations, activity: activity)
        videoCompression = VideoCompressionStore(repository: ports.videoCompression, store: store, activity: activity, notifier: notifier, toaster: toaster, now: { .now })
        tickets = TicketsStore(repository: ports.tracker, config: config, activity: activity, toaster: toaster, events: events, store: store)
        aiSessions = AISessionsStore(repository: ports.aiSessions, session: session, worktrees: worktrees, store: store)
        updates = UpdateStore(repository: ports.updates, toaster: toaster, activity: activity, checkInterval: .seconds(300), statusInterval: .seconds(1), now: { .now })
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
            crashes: crashes,
            session: session,
            config: config,
            workspace: workspace,
            videoCompression: videoCompression,
            toaster: toaster
        )
    }
}
