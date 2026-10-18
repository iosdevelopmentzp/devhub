import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ConfigActionsStore {
    private(set) var pending: PendingConfigAction?
    private(set) var runs: [String: ConfigActionRun] = [:]
    private(set) var progress: ConfigActionProgress?
    private(set) var lastRunDates: [String: Date]

    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let scripts: any ScriptRunning
    @ObservationIgnored let tools: any ToolLocating
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let checkout: any CheckoutContext
    @ObservationIgnored let worktrees: any WorktreeLookup
    @ObservationIgnored let codeHosts: any CodeHostLookup
    @ObservationIgnored let build: any BuildLookup
    @ObservationIgnored let workspace: WorkspaceActions
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let notifier: Notifier
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let store: any KeyValueStore
    @ObservationIgnored let appVersion: String
    @ObservationIgnored let home: String
    @ObservationIgnored var tasks: [String: Task<Void, Never>] = [:]

    init(
        config: ConfigStore,
        scripts: any ScriptRunning,
        tools: any ToolLocating,
        session: ProjectSession,
        checkout: any CheckoutContext,
        worktrees: any WorktreeLookup,
        codeHosts: any CodeHostLookup,
        build: any BuildLookup,
        workspace: WorkspaceActions,
        toaster: Toaster,
        activity: ActivityLog,
        notifier: Notifier,
        events: AppEvents,
        store: any KeyValueStore,
        appVersion: String,
        home: String
    ) {
        self.config = config
        self.scripts = scripts
        self.tools = tools
        self.session = session
        self.checkout = checkout
        self.worktrees = worktrees
        self.codeHosts = codeHosts
        self.build = build
        self.workspace = workspace
        self.toaster = toaster
        self.activity = activity
        self.notifier = notifier
        self.events = events
        self.store = store
        self.appVersion = appVersion
        self.home = home
        lastRunDates = store.decode([String: Date].self, forKey: Keys.lastRun) ?? [:]
    }

    var effective: EffectiveProject {
        config.effective(detectedSchemes: build.schemeOptions, detectedBaseBranch: worktrees.baseBranch)
    }

    var currentBranch: String? {
        checkout.currentBranch ?? worktrees.worktree(atPath: checkout.checkoutPath)?.branch ?? worktrees.mainWorktree?.branch
    }

    func actions(for placement: Placement) -> [CatalogAction] {
        ActionCatalogPolicy.actions(for: placement, resolved: config.resolved, facts: facts)
    }

    func isRunning(_ id: String) -> Bool {
        runs[id]?.isRunning == true
    }

    func lastRun(of id: String) -> Date? {
        lastRunDates[runKey(id)]
    }

    func pending(in slot: String) -> PendingConfigAction? {
        guard let pending, pending.slot == slot else { return nil }
        return pending
    }

    func request(_ action: ResolvedAction, item: ActionItemContext, slot: String) {
        let catalog = CatalogAction.config(action)
        guard catalog.isRunnable else {
            toaster.show("Run chmod +x on \(catalog.fileName ?? action.config.title) first")
            return
        }
        guard catalog.needsPrompt else {
            run(action, item: item, inputs: [:])
            return
        }
        pending = PendingConfigAction(action: action, slot: slot, item: item, inputs: initialInputs(for: action, item: item))
    }

    func request(id: String, item: ActionItemContext, slot: String) {
        guard let action = ActionCatalogPolicy.action(id: id, resolved: config.resolved)?.resolved else {
            toaster.show("The action \(id) is no longer in the config")
            return
        }
        request(action, item: item, slot: slot)
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

    func runWithDefaults(_ action: ResolvedAction, item: ActionItemContext) {
        run(action, item: item, inputs: initialInputs(for: action, item: item))
    }

    func run(_ action: ResolvedAction, item: ActionItemContext, inputs: [String: String]) {
        guard isRunning(action.id) == false else { return }
        remember(inputs, for: action)
        runs[action.id] = ConfigActionRun(status: .running, startedAt: Date())
        tasks[action.id] = Task { [weak self] in
            guard let self else { return }
            await execute(action, item: item, inputs: inputs)
        }
    }

    func stop(_ id: String) {
        tasks[id]?.cancel()
    }

    func dismissResult(of id: String) {
        guard isRunning(id) == false else { return }
        runs[id] = nil
    }

    func setRun(_ run: ConfigActionRun?, for id: String) {
        runs[id] = run
    }

    func setProgress(_ value: ConfigActionProgress?) {
        progress = value
    }

    func recordRun(of id: String, at date: Date) {
        lastRunDates[runKey(id)] = date
        store.encode(lastRunDates, forKey: Keys.lastRun)
    }

    private var facts: ActionConditionFacts {
        ActionConditionFacts(
            isGitClean: checkout.currentBranch == nil ? worktrees.mainWorktree.map { $0.changedFiles == 0 } : checkout.isMainCheckoutClean,
            isTargetBooted: build.target?.state == .booted,
            installedTools: Set(config.resolved.actions.compactMap(\.config.when?.tool).filter(tools.isInstalled)),
            kind: effective.kind,
            hostKind: codeHosts.kind
        )
    }

    private func runKey(_ id: String) -> String {
        session.selectedProject.path + "|" + id
    }

    private func initialInputs(for action: ResolvedAction, item: ActionItemContext) -> [String: String] {
        let saved = store.decode([String: String].self, forKey: Keys.inputs) ?? [:]
        var values: [String: String] = [:]
        for input in action.config.inputs ?? [] {
            if input.remember == true, let stored = saved[runKey(action.id) + "|" + input.key] {
                values[input.key] = stored
            } else {
                values[input.key] = ActionContextPolicy.defaultValue(
                    for: input,
                    branch: item.branch ?? currentBranch ?? "",
                    simulatorUDID: item.simulatorUDID ?? build.target?.id ?? "",
                    scheme: effective.scheme ?? build.selectedScheme
                )
            }
        }
        return values
    }

    private func remember(_ inputs: [String: String], for action: ResolvedAction) {
        let remembered = (action.config.inputs ?? []).filter { $0.remember == true }
        guard remembered.isEmpty == false else { return }
        var saved = store.decode([String: String].self, forKey: Keys.inputs) ?? [:]
        for input in remembered {
            saved[runKey(action.id) + "|" + input.key] = inputs[input.key] ?? ""
        }
        store.encode(saved, forKey: Keys.inputs)
    }

    private enum Keys {
        static let lastRun = "configActions.lastRun"
        static let inputs = "configActions.inputs"
    }
}
