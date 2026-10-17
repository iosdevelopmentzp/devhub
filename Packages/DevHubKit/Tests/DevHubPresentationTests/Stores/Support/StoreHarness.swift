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
    let activity = ActivityLog(events: [])
    let session: ProjectSession
    private(set) var posted: [AppEvent] = []
    private(set) var copied: [String] = []
    private var recording: SubscriptionToken?

    init(projects: [Project], store: InMemoryKeyValueStore) {
        let (ports, spies) = Ports.spies()
        self.ports = ports
        self.spies = spies
        self.store = store
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
        build: build,
        workspace: workspace,
        toaster: toaster,
        activity: activity,
        events: events,
        store: store,
        appVersion: "1.0",
        home: "/Users/alex"
    )

    lazy var workspace = WorkspaceActions(settings: settings, activity: activity, opener: ports.opener)

    lazy var usage = UsageStore(repository: ports.usage)

    lazy var worktrees = WorktreesStore(
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
        events: events,
        store: store
    )

    lazy var changes = GitChangesStore(
        repository: ports.changes,
        git: ports.git,
        discardChange: useCases.discardChange,
        commitChanges: useCases.commit,
        checkout: git,
        activity: activity,
        events: events
    )

    lazy var history = CommitHistoryStore(repository: ports.changes, checkout: git, activity: activity, events: events, store: store)

    lazy var mergeRequests = MergeRequestStore(repository: ports.mergeRequests, checkout: git, events: events)

    lazy var gitLabRemote = GitLabRemote(git: ports.git, worktrees: worktrees, events: events)

    lazy var gitLab = GitLabStore(repository: ports.mergeRequests, remote: gitLabRemote, activity: activity, events: events, store: store)

    lazy var openMergeRequests = OpenMergeRequestsStore(repository: ports.mergeRequests, remote: gitLabRemote, activity: activity, events: events)

    lazy var mergeRequestDetails = MergeRequestDetailStore(repository: ports.mergeRequests, remote: gitLabRemote, prompts: ports.reviewPrompts, activity: activity, events: events)

    lazy var newMergeRequest = NewMergeRequestStore(
        git: ports.git,
        mergeRequests: ports.mergeRequests,
        createMergeRequest: useCases.createMergeRequest,
        checkout: git,
        remote: gitLabRemote,
        activity: activity,
        events: events
    )

    lazy var simulators = SimulatorsStore(repository: ports.simulators, activity: activity, events: events, store: store)

    lazy var identity = IdentityStore(
        repository: ports.identity,
        launchInstalledApp: useCases.launchInstalledApp,
        session: session,
        simulators: simulators,
        attacher: ports.attacher,
        activity: activity,
        events: events,
        store: store
    )

    lazy var build = BuildStore(
        repository: ports.build,
        buildAndRun: useCases.buildAndRun,
        prepareCheckout: useCases.prepareBuildCheckout,
        session: session,
        worktrees: worktrees,
        simulators: simulators,
        identity: identity,
        attacher: ports.attacher,
        activity: activity,
        events: events,
        store: store
    )

    lazy var logs = LogsStore(repository: ports.logs, session: session, store: store)

    lazy var mockSets = MockSetsStore(repository: ports.mockSets, session: session, activity: activity, events: events)

    lazy var mockServer = MockServerStore(
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

    lazy var network = NetworkStore(session: session, simulators: simulators, mockTraffic: mockServer, events: events, store: store)

    lazy var messaging = MessagingStore(repository: ports.messaging, session: session, activity: activity, events: events, store: store)

    lazy var claudeSessions = ClaudeSessionsStore(repository: ports.claudeSessions, session: session, store: store)


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
