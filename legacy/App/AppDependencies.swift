import Foundation
import SwiftUI

@MainActor
final class AppDependencies {
    let preferences: AppPreferences
    let settings: SettingsStore
    let events: AppEvents
    let activity: ActivityLog
    let toaster: Toaster
    let hints: HintCenter
    let layout: WindowLayout
    let navigator: Navigator
    let session: ProjectSession
    let config: ConfigStore
    let catalog: ActionCatalog
    let runner: ActionRunner
    let outputPanel: OutputPanelState
    let commandLog: CommandLog
    let home: HomeStore
    let git: GitStore
    let worktrees: WorktreesStore
    let simulators: SimulatorsStore
    let build: BuildStore
    let logs: LogsStore
    let ai: AIStore
    let usage: UsageStore
    let settingsTab: SettingsTabStore

    private(set) var windows: AppWindows?

    init(providers: Providers, preferences: AppPreferences) {
        self.preferences = preferences
        let events = AppEvents()
        let activity = ActivityLog()
        let toaster = Toaster()
        let settings = SettingsStore(preferences: preferences)
        let navigator = Navigator(preferences: preferences)
        let session = ProjectSession(
            preferences: preferences,
            git: providers.git,
            detector: providers.projects,
            events: events,
            activity: activity,
            toaster: toaster
        )
        let config = ConfigStore(provider: providers.config, session: session, events: events)
        let projectActions = ProjectActions(
            session: session,
            config: config,
            workspace: providers.workspace,
            settings: settings,
            activity: activity,
            toaster: toaster
        )
        self.events = events
        self.activity = activity
        self.settings = settings
        self.session = session
        self.config = config
        self.toaster = toaster
        self.navigator = navigator
        catalog = ActionCatalog(config: config, session: session, settings: settings, tools: providers.tools)
        runner = ActionRunner(
            session: session,
            config: config,
            projectActions: projectActions,
            shell: .shared,
            toaster: toaster,
            activity: activity,
            events: events,
            navigator: navigator,
            preferences: preferences
        )
        hints = HintCenter()
        layout = WindowLayout(preferences: preferences)
        outputPanel = OutputPanelState(preferences: preferences, events: events)
        let commandLog = CommandLog(recorder: .shared)
        commandLog.onFailure = { entry in
            events.post(.commandFailed(entry.command))
        }
        self.commandLog = commandLog
        home = HomeStore(session: session, config: config, projectActions: projectActions)
        let gitExecutor = GitExecutor(provider: providers.git, activity: activity, toaster: toaster)
        let worktrees = WorktreesStore(
            provider: providers.worktrees,
            git: providers.git,
            executor: gitExecutor,
            session: session,
            config: config,
            events: events,
            activity: activity,
            toaster: toaster,
            projectActions: projectActions
        )
        self.worktrees = worktrees
        git = GitStore(
            provider: providers.git,
            hosting: providers.hosting,
            executor: gitExecutor,
            session: session,
            config: config,
            worktrees: worktrees,
            events: events,
            activity: activity,
            toaster: toaster,
            projectActions: projectActions,
            preferences: preferences
        )
        let simulators = SimulatorsStore(
            provider: providers.simulators,
            session: session,
            config: config,
            events: events,
            activity: activity,
            toaster: toaster,
            preferences: preferences,
            projectActions: projectActions
        )
        self.simulators = simulators
        let build = BuildStore(
            provider: providers.build,
            simulatorProvider: providers.simulators,
            debugger: providers.debugger,
            session: session,
            config: config,
            git: git,
            worktrees: worktrees,
            simulators: simulators,
            events: events,
            activity: activity,
            toaster: toaster,
            preferences: preferences,
            projectActions: projectActions
        )
        self.build = build
        runner.onBuild = { mode in
            navigator.show("simulators")
            build.start(mode)
        }
        logs = LogsStore(provider: providers.logs, simulators: simulators, config: config, activity: activity, preferences: preferences)
        ai = AIStore(provider: providers.ai, workspace: providers.workspace, session: session, settings: settings, preferences: preferences, activity: activity, toaster: toaster)
        usage = UsageStore(provider: providers.usage, settings: settings, layout: layout, activity: activity)
        settingsTab = SettingsTabStore(session: session, config: config, projectActions: projectActions, settings: settings)
    }

    static func live() -> AppDependencies {
        let dependencies = AppDependencies(providers: .live, preferences: AppPreferences(defaults: .standard))
        dependencies.windows = AppWindows(
            layout: dependencies.layout,
            settings: dependencies.settings,
            navigator: dependencies.navigator,
            session: dependencies.session
        ) { actions in
            AnyView(RootView().inject(dependencies).environment(\.panelActions, actions))
        }
        Task { await dependencies.session.start() }
        dependencies.usage.startPolling()
        MenuBarUsage.bind(usage: dependencies.usage, windows: dependencies.windows)
        return dependencies
    }

    static func mock() -> AppDependencies {
        let suite = "DevHub.mock"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let dependencies = AppDependencies(providers: .mock, preferences: AppPreferences(defaults: defaults))
        dependencies.session.add(path: NSHomeDirectory())
        return dependencies
    }
}

extension View {
    func inject(_ dependencies: AppDependencies) -> some View {
        environment(dependencies.settings)
            .environment(dependencies.activity)
            .environment(dependencies.toaster)
            .environment(dependencies.hints)
            .environment(dependencies.layout)
            .environment(dependencies.navigator)
            .environment(dependencies.session)
            .environment(dependencies.config)
            .environment(dependencies.catalog)
            .environment(dependencies.runner)
            .environment(dependencies.outputPanel)
            .environment(dependencies.commandLog)
            .environment(dependencies.home)
            .environment(dependencies.git)
            .environment(dependencies.worktrees)
            .environment(dependencies.simulators)
            .environment(dependencies.build)
            .environment(dependencies.logs)
            .environment(dependencies.ai)
            .environment(dependencies.usage)
            .environment(dependencies.settingsTab)
    }

    func previewEnvironment() -> some View {
        inject(AppDependencies.mock())
            .frame(width: 720, height: 820)
    }
}
