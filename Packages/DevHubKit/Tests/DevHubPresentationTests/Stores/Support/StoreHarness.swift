import Foundation
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

final class StoreHarness {
    let ports: Ports
    let spies: PortSpies
    let useCases: UseCases
    let store: InMemoryKeyValueStore
    let events = AppEvents()
    let activity: ActivityLog
    let session: ProjectSession
    private(set) var posted: [AppEvent] = []
    private(set) var copied: [String] = []
    private(set) var requestedFileNames: [String] = []
    var saveTarget: URL? = URL(fileURLWithPath: "/tmp/DevHubTests/ci-diagnostics.txt")
    private var recording: SubscriptionToken?

    init(projects: [Project], store: InMemoryKeyValueStore) {
        let (ports, spies) = Ports.spies()
        self.ports = ports
        self.spies = spies
        self.store = store
        activity = ActivityLog(events: [], store: store)
        useCases = UseCases(ports: ports)
        session = ProjectSession(projects: projects, selectedProjectID: nil, store: store, events: events, detector: ports.projectDetector)
        spies.worktrees.baseBranchResult = "origin/main"
        recording = events.subscribe { [weak self] event in
            guard let self else { return }
            posted.append(event)
        }
    }

    convenience init() {
        self.init(projects: [ProjectSample.app], store: InMemoryKeyValueStore())
    }

    convenience init(projects: [Project]) {
        self.init(projects: projects, store: InMemoryKeyValueStore())
    }

    convenience init(store: InMemoryKeyValueStore) {
        self.init(projects: [ProjectSample.app], store: store)
    }

    // MARK: Stores

    lazy var toaster = Toaster { [weak self] value in
        guard let self else { return }
        copied.append(value)
    }

    lazy var settings = SettingsStore(values: AppSettings(), store: store)

    lazy var config = ConfigStore(repository: ports.config, session: session, events: events)

    lazy var configActions = ConfigActionsStore(
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
        appVersion: "1.0",
        home: "/Users/alex"
    )

    lazy var notifier = Notifier(repository: ports.notifications, settings: settings, activity: activity)

    lazy var doctor = DoctorStore(checkTools: useCases.checkTools, attacher: ports.attacher)
    lazy var xcodes = XcodeSelectionStore(repository: ports.xcodes, environment: ports.toolEnvironment, session: session, config: config, activity: activity, events: events)
    lazy var keepAwake = KeepAwakeStore(preventer: ports.sleep, activity: activity)

    lazy var workspace = WorkspaceActions(settings: settings, activity: activity, opener: ports.opener, files: ports.textFiles)

    lazy var usage = UsageStore(repository: ports.usage, copilotRepository: ports.copilotUsage)

    lazy var worktrees = WorktreesStore(
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

    lazy var git = GitStore(
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

    lazy var operations = OperationLog()

    lazy var branchMarks = BranchMarksStore(session: session, events: events, store: store)
    lazy var scriptList = ScriptListStore(session: session, events: events, store: store)

    lazy var changes = GitChangesStore(
        repository: ports.changes,
        git: ports.git,
        discardChange: useCases.discardChange,
        commitChanges: useCases.commit,
        checkout: git,
        activity: activity,
        operations: operations,
        events: events
    )

    lazy var history = CommitHistoryStore(repository: ports.changes, checkout: git, activity: activity, events: events, store: store)

    lazy var branchPullRequest = BranchPullRequestStore(repository: ports.codeHost, checkout: git, events: events)

    lazy var codeHostRemote = CodeHostRemote(git: ports.git, worktrees: worktrees, events: events)

    lazy var ciProjects = CIProjectResolver(config: config, worktrees: worktrees, remote: codeHostRemote, tools: ports.tools, events: events)

    lazy var ciHistory = CIWorkflowHistory(session: session, events: events, store: store)

    lazy var ciBranchRuns = CIBranchRunsStore(ci: ports.ci, projects: ciProjects, checkout: git, activity: activity, operations: operations, notifier: notifier, events: events, basePollInterval: .milliseconds(5))

    lazy var pullRequestHiddenFiles = PullRequestHiddenFiles(session: session, events: events, store: store)
    lazy var pullRequestReviews = PullRequestReviewMemory(session: session, settings: settings, events: events, store: store, now: { Date(timeIntervalSince1970: 1_800_000_000) })

    lazy var ciAutoRerun = CIAutoRerunStore(
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

    lazy var pullRequests = PullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, openRequests: openPullRequests, activity: activity, operations: operations, events: events, store: store)
    lazy var pullRequestPeople = PullRequestPeopleStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, operations: operations, events: events)
    lazy var aiText = AITextStore(
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

    lazy var openPullRequests = OpenPullRequestsStore(repository: ports.codeHost, remote: codeHostRemote, session: session, checkout: git, settings: settings, activity: activity, notifier: notifier, events: events, store: store, now: { .now })

    lazy var ciWatch = CIWatchStore(
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
        pollInterval: .milliseconds(5)
    )

    lazy var commandLog = CommandLog()

    lazy var ciDiagnostics = CIDiagnosticsStore(
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
        home: "/Users/alex",
        appVersion: "1.0",
        now: { Date(timeIntervalSince1970: 1_800_000_000) },
        chooseFile: { [weak self] name in
            guard let self else { return nil }
            requestedFileNames.append(name)
            return saveTarget
        }
    )

    lazy var inbox = InboxStore(repository: ports.codeHost, remote: codeHostRemote, activity: activity, notifier: notifier, events: events)

    lazy var pullRequestDetails = PullRequestDetailStore(
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
        ciPollInterval: .milliseconds(5),
        events: events
    )

    lazy var newPullRequest = NewPullRequestStore(
        git: ports.git,
        codeHost: ports.codeHost,
        createPullRequest: useCases.createPullRequest,
        checkout: git,
        remote: codeHostRemote,
        activity: activity,
        events: events
    )

    lazy var simulators = SimulatorsStore(repository: ports.simulators, devices: ports.devices, activity: activity, operations: operations, events: events, store: store)

    lazy var identity = IdentityStore(
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

    lazy var simulatorStatuses = SimulatorStatusStore(readStatus: useCases.readSimulatorStatus, config: config, session: session, simulators: simulators, build: build, codeHosts: codeHostRemote, launcher: ports.launcher, events: events, settleDelay: .zero)

    lazy var build: BuildStore = {
        let build = makeBuild()
        identity.use(build: build)
        return build
    }()

    private func makeBuild() -> BuildStore {
        BuildStore(
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
    }

    lazy var testRuns = TestRunsStore(runTests: useCases.runTests, build: build, worktrees: worktrees, config: config, activity: activity, notifier: notifier, events: events, prompts: ports.reviewPrompts)

    lazy var logs = LogsStore(repository: ports.logs, session: session, config: config, simulators: simulators, identity: identity, activity: activity, store: store)

    lazy var crashes = CrashReportsStore(repository: ports.crashes, prompts: ports.reviewPrompts, activity: activity, notifier: notifier, events: events)

    lazy var mockSets = MockSetsStore(repository: ports.mockSets, session: session, config: config, activity: activity, events: events)

    lazy var mockServer = MockServerStore(
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

    lazy var network = NetworkStore(session: session, simulators: simulators, mockTraffic: mockServer, events: events, store: store)

    lazy var simulatorQA = SimulatorQAStore(repository: ports.simulatorSettings, media: ports.media, store: store, activity: activity, operations: operations, screenshotFolder: "/tmp/DevHubTests/Shots", now: { Date(timeIntervalSince1970: 1_800_000_000) })
    lazy var media = MediaStore(repository: ports.media, operations: operations, activity: activity)
    lazy var appData = AppDataStore(repository: ports.appData, operations: operations, activity: activity, events: events)
    lazy var diskCleanup = DiskCleanupStore(repository: ports.diskCleanup, operations: operations, activity: activity)
    lazy var navigator = Navigator(store: store, customTabs: config)
    lazy var videoCompression = VideoCompressionStore(repository: ports.videoCompression, store: store, activity: activity, notifier: notifier, toaster: toaster, now: { Date(timeIntervalSince1970: 1_800_000_000) })

    lazy var tickets = TicketsStore(repository: ports.tracker, config: config, activity: activity, toaster: toaster, events: events, store: store)
    lazy var messaging = MessagingStore(repository: ports.messaging, session: session, identity: identity, activity: activity, operations: operations, events: events, store: store)

    lazy var aiSessions = AISessionsStore(repository: ports.aiSessions, session: session, worktrees: worktrees, store: store)

    lazy var updates = UpdateStore(repository: ports.updates, toaster: toaster, activity: activity, checkInterval: .seconds(3600), statusInterval: .milliseconds(5), now: { Date(timeIntervalSince1970: 1_800_000_000) })


    // MARK: Observations

    var postedLabels: [String] {
        posted.map(\.label)
    }

    func postCount(_ label: String) -> Int {
        postedLabels.filter { $0 == label }.count
    }

    var activityTitles: [String] {
        activity.events.map(\.title)
    }

    var lastActivity: ActivityEvent? {
        activity.events.first
    }

    func clearPosted() {
        posted = []
    }

    func settle() async {
        for _ in 0..<100 {
            await Task.yield()
        }
    }
}
