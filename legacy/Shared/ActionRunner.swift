import Foundation
import Observation

@MainActor
@Observable
final class ActionRunner {
    private(set) var pending: PendingRun?
    private(set) var results: [String: ActionResult] = [:]
    private(set) var progress: ActionProgress?
    private(set) var lastRunDates: [String: Date]

    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let projectActions: ProjectActions
    @ObservationIgnored let shell: ShellRunner
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let navigator: Navigator
    @ObservationIgnored let preferences: AppPreferences
    @ObservationIgnored var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored var onBuild: (RunMode) -> Void = { _ in }

    init(
        session: ProjectSession,
        config: ConfigStore,
        projectActions: ProjectActions,
        shell: ShellRunner,
        toaster: Toaster,
        activity: ActivityLog,
        events: AppEvents,
        navigator: Navigator,
        preferences: AppPreferences
    ) {
        self.session = session
        self.config = config
        self.projectActions = projectActions
        self.shell = shell
        self.toaster = toaster
        self.activity = activity
        self.events = events
        self.navigator = navigator
        self.preferences = preferences
        lastRunDates = preferences.value([String: Date].self, for: .actionLastRun) ?? [:]
    }

    var contextBuilder: ActionContextBuilder {
        ActionContextBuilder(session: session, config: config)
    }

    func isRunning(_ action: CatalogAction) -> Bool {
        results[action.id]?.isRunning == true
    }

    func lastRun(of action: CatalogAction) -> Date? {
        lastRunDates[runKey(action.id)]
    }

    func pending(in slot: String) -> PendingRun? {
        guard let pending, pending.slot == slot else { return nil }
        return pending
    }

    func request(_ action: CatalogAction, item: ActionItemContext, slot: String) {
        guard action.isRunnable else {
            toaster.show("Run chmod +x on \(action.fileName ?? action.title) first", tint: .orange)
            return
        }
        guard action.needsPrompt else {
            run(action, item: item, inputs: [:])
            return
        }
        pending = PendingRun(action: action, slot: slot, item: item, inputs: initialInputs(for: action))
    }

    func setInput(_ value: String, for key: String) {
        pending?.inputs[key] = value
    }

    func cancelPending() {
        pending = nil
    }

    func confirmPending() {
        guard let current = pending else { return }
        pending = nil
        run(current.action, item: current.item, inputs: current.inputs)
    }

    func runWithDefaults(_ action: CatalogAction, item: ActionItemContext) {
        run(action, item: item, inputs: initialInputs(for: action))
    }

    func run(_ action: CatalogAction, item: ActionItemContext, inputs: [String: String]) {
        guard isRunning(action) == false else { return }
        switch action.source {
        case let .builtin(builtin):
            performBuiltin(builtin)
        case let .config(resolved):
            remember(inputs, for: action)
            tasks[action.id] = Task { [weak self] in
                guard let self else { return }
                await execute(action, resolved, item: item, inputs: inputs)
            }
        }
    }

    func stop(_ action: CatalogAction) {
        tasks[action.id]?.cancel()
    }

    func dismissResult(of action: CatalogAction) {
        guard results[action.id]?.isRunning != true else { return }
        results[action.id] = nil
    }

    func setResult(_ result: ActionResult?, for id: String) {
        results[id] = result
    }

    func setProgress(_ value: ActionProgress?) {
        progress = value
    }

    func recordRun(of id: String, at date: Date) {
        lastRunDates[runKey(id)] = date
        preferences.setValue(lastRunDates, for: .actionLastRun)
    }

    func runKey(_ id: String) -> String {
        (session.project?.path ?? "") + "|" + id
    }

    private func initialInputs(for action: CatalogAction) -> [String: String] {
        let saved = preferences.value([String: String].self, for: .actionInputs) ?? [:]
        var values: [String: String] = [:]
        for input in action.inputs {
            let key = runKey(action.id) + "|" + input.key
            if input.remember == true, let stored = saved[key] {
                values[input.key] = stored
            } else {
                values[input.key] = contextBuilder.defaultValue(for: input)
            }
        }
        return values
    }

    private func remember(_ inputs: [String: String], for action: CatalogAction) {
        let remembered = action.inputs.filter { $0.remember == true }
        guard remembered.isEmpty == false else { return }
        var saved = preferences.value([String: String].self, for: .actionInputs) ?? [:]
        for input in remembered {
            saved[runKey(action.id) + "|" + input.key] = inputs[input.key] ?? ""
        }
        preferences.setValue(saved, for: .actionInputs)
    }

    private func performBuiltin(_ builtin: BuiltinAction) {
        switch builtin {
        case .buildRun:
            onBuild(.buildRun)
        case .runAttach:
            onBuild(.runAttach)
        case .openEditor: projectActions.openInEditor()
        case .openFolder: projectActions.revealInFinder()
        case .terminal: projectActions.openTerminal()
        case .copyBranch: projectActions.copyBranch()
        case .repository: projectActions.openRepository()
        case .newPullRequest: projectActions.openNewRequest()
        }
    }
}
