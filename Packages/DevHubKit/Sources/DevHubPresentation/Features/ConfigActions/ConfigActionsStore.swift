import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class ConfigActionsStore {
    private(set) var pending: PendingConfigAction?
    private(set) var runs: [String: ConfigActionRun] = [:]
    private(set) var lastRunDates: [String: Date]
    private(set) var tabInputs: [String: [String: String]]
    private(set) var recentInputs: [String: [String]]
    private(set) var copyHistory: [ConfigCopyRecord]

    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let scripts: any ScriptRunning
    @ObservationIgnored let tools: any ToolLocating
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let checkout: any CheckoutContext
    @ObservationIgnored let worktrees: any WorktreeLookup
    @ObservationIgnored let codeHosts: any CodeHostLookup
    @ObservationIgnored let build: any BuildLookup
    @ObservationIgnored let simulators: any SimulatorLookup
    @ObservationIgnored let launcher: any AppLaunchRepository
    @ObservationIgnored let workspace: WorkspaceActions
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let operations: OperationLog
    @ObservationIgnored let notifier: Notifier
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let store: any KeyValueStore
    @ObservationIgnored let appVersion: String
    @ObservationIgnored let home: String
    @ObservationIgnored var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored var operationIDs: [String: OperationRecord.ID] = [:]

    init(
        config: ConfigStore,
        scripts: any ScriptRunning,
        tools: any ToolLocating,
        session: ProjectSession,
        checkout: any CheckoutContext,
        worktrees: any WorktreeLookup,
        codeHosts: any CodeHostLookup,
        build: any BuildLookup,
        simulators: any SimulatorLookup,
        launcher: any AppLaunchRepository,
        workspace: WorkspaceActions,
        toaster: Toaster,
        activity: ActivityLog,
        operations: OperationLog,
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
        self.simulators = simulators
        self.launcher = launcher
        self.workspace = workspace
        self.toaster = toaster
        self.activity = activity
        self.operations = operations
        self.notifier = notifier
        self.events = events
        self.store = store
        self.appVersion = appVersion
        self.home = home
        lastRunDates = store.decode([String: Date].self, forKey: Keys.lastRun) ?? [:]
        tabInputs = store.decode([String: [String: String]].self, forKey: Keys.tabInputs) ?? [:]
        recentInputs = store.decode([String: [String]].self, forKey: Keys.recentInputs) ?? [:]
        copyHistory = store.decode([ConfigCopyRecord].self, forKey: Keys.copyHistory) ?? []
    }

    var effective: EffectiveProject {
        config.effective(detectedSchemes: build.schemeOptions, detectedBaseBranch: worktrees.baseBranch)
    }

    var currentBranch: String? {
        checkout.currentBranch ?? worktrees.worktree(atPath: checkout.checkoutPath)?.branch ?? worktrees.mainWorktree?.branch
    }

    func isVisible(_ action: CatalogAction) -> Bool {
        guard let config = action.resolved?.config else { return true }
        return ActionCatalogPolicy.isVisible(config, facts: facts)
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
        let inputs = initialInputs(for: action, item: item)
        guard ActionConfirmationPolicy.needsPrompt(action.config, sharedInputs: sharedInputs(of: item), values: item.inputs.merging(inputs) { _, own in own }) else {
            run(action, item: item, inputs: [:])
            return
        }
        pending = PendingConfigAction(action: action, slot: slot, item: item, inputs: inputs)
    }

    func confirmation(for pending: PendingConfigAction) -> String? {
        ActionConfirmationPolicy.text(for: pending.action.config, sharedInputs: sharedInputs(of: pending.item), values: pending.item.inputs.merging(pending.inputs) { _, own in own })
    }

    func copyPreview(for pending: PendingConfigAction) -> String? {
        guard let template = pending.action.config.run.copyTemplate else { return nil }
        let context = ActionContextPolicy.make(contextInputs(pending.action, item: pending.item, inputs: pending.inputs))
        return PlaceholderExpander.expand(template, values: context.placeholders, encodesForURL: false)
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
        recordRecents(inputs, inputs: action.config.inputs ?? [], scope: runKey(action.id))
        if let tabID = item.tabID {
            recordRecents(item.inputs, inputs: sharedInputs(of: item), scope: tabKey(tabID))
        }
        runs[action.id] = ConfigActionRun(status: .running, startedAt: Date())
        let operationID = operations.start(
            action.config.title,
            at: .action(action.id),
            retry: { [weak self] in
                guard let self else { return }
                run(action, item: item, inputs: inputs)
            },
            stop: { [weak self] in
                guard let self else { return }
                stop(action.id)
            }
        )
        operationIDs[action.id] = operationID
        tasks[action.id] = Task { [weak self] in
            guard let self else { return }
            await OperationScope.$current.withValue(operationID) {
                await execute(action, item: item, inputs: inputs)
            }
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

    func recordRun(of id: String, at date: Date) {
        lastRunDates[runKey(id)] = date
        store.encode(lastRunDates, forKey: Keys.lastRun)
    }

    func recentValues(for key: String, scope: String) -> [String] {
        recentInputs[scope + "|" + key] ?? []
    }

    func forgetRecent(_ value: String, for key: String, scope: String) {
        recentInputs[scope + "|" + key]?.removeAll { $0 == value }
        store.encode(recentInputs, forKey: Keys.recentInputs)
    }

    func actionScope(_ id: String) -> String {
        runKey(id)
    }

    func tabScope(_ tabID: String) -> String {
        tabKey(tabID)
    }

    func tabInputValues(for tab: TabConfig) -> [String: String] {
        let saved = tabInputs[tabKey(tab.id)] ?? [:]
        var values: [String: String] = [:]
        for input in tab.inputs ?? [] {
            values[input.key] = saved[input.key] ?? ActionContextPolicy.defaultValue(
                for: input,
                branch: currentBranch ?? "",
                simulatorUDID: build.target?.id ?? "",
                scheme: effective.scheme ?? build.selectedScheme
            )
        }
        return values
    }

    func setTabInput(_ value: String, for key: String, tab: TabConfig) {
        var values = tabInputValues(for: tab)
        values[key] = value
        tabInputs[tabKey(tab.id)] = values
        store.encode(tabInputs, forKey: Keys.tabInputs)
    }

    func copyHistory(in tabID: String?) -> [ConfigCopyRecord] {
        copyHistory.filter { $0.projectPath == session.selectedProject.path && $0.tabID == tabID }
    }

    func recordCopy(_ record: ConfigCopyRecord) {
        copyHistory.removeAll { $0.id == record.id || ($0.projectPath == record.projectPath && $0.text == record.text) }
        copyHistory.insert(record, at: 0)
        let own = copyHistory.filter { $0.projectPath == record.projectPath }
        if own.count > Limits.copyHistory {
            let dropped = Set(own.suffix(from: Limits.copyHistory).map(\.id))
            copyHistory.removeAll { dropped.contains($0.id) }
        }
        store.encode(copyHistory, forKey: Keys.copyHistory)
    }

    func resend(_ record: ConfigCopyRecord) {
        toaster.copy(record.text, label: record.text)
        var sent = record
        sent.date = Date()
        recordCopy(sent)
        if let open = record.open, workspace.openTarget(open, relativeTo: ProjectPath(session.selectedProject.path).expanded) == false {
            activity.log(record.title, detail: "Cannot open \(open)", outcome: .failure)
            toaster.show("Cannot open \(open)")
            return
        }
        activity.log(record.title, detail: "Copied again: \(record.text)", outcome: .success)
    }

    func removeCopy(id: ConfigCopyRecord.ID) {
        copyHistory.removeAll { $0.id == id }
        store.encode(copyHistory, forKey: Keys.copyHistory)
    }

    func clearCopyHistory(in tabID: String?) {
        let project = session.selectedProject.path
        copyHistory.removeAll { $0.projectPath == project && $0.tabID == tabID }
        store.encode(copyHistory, forKey: Keys.copyHistory)
    }

    func contextInputs(_ action: ResolvedAction, item: ActionItemContext, inputs: [String: String], containers: AppContainers = .none) -> ActionContextInputs {
        let project = session.selectedProject
        let target = build.target
        let udid = item.simulatorUDID ?? target?.id ?? ""
        return ActionContextInputs(
            projectPath: ProjectPath(project.path).expanded,
            projectName: project.name,
            checkoutPath: ProjectPath(checkout.checkoutPath.isEmpty ? project.path : checkout.checkoutPath).expanded,
            branch: currentBranch ?? "",
            effective: effective,
            simulatorUDID: target?.id ?? "",
            simulatorName: target?.name ?? "",
            appPath: build.lastBuiltAppPath() ?? "",
            configDir: action.origin.directory,
            item: item,
            inputs: inputs,
            version: appVersion,
            profileID: target.flatMap { build.profile(for: $0.id) }?.id ?? "",
            hostKind: codeHosts.kind,
            containers: containers,
            simulatorState: simulators.simulator(id: udid)?.state,
            isPhysicalDevice: simulators.simulator(id: udid)?.isPhysical == true
        )
    }

    private func sharedInputs(of item: ActionItemContext) -> [ActionInput] {
        guard let tabID = item.tabID else { return [] }
        return config.resolved.tabs.first { $0.id == tabID }?.inputs ?? []
    }

    private func recordRecents(_ values: [String: String], inputs: [ActionInput], scope: String) {
        let tracked = inputs.filter { $0.recent == true }
        guard tracked.isEmpty == false else { return }
        for input in tracked {
            guard let value = values[input.key]?.trimmingCharacters(in: .whitespacesAndNewlines), value.isEmpty == false else { continue }
            var list = recentInputs[scope + "|" + input.key] ?? []
            list.removeAll { $0 == value }
            list.insert(value, at: 0)
            recentInputs[scope + "|" + input.key] = Array(list.prefix(Limits.recentValues))
        }
        store.encode(recentInputs, forKey: Keys.recentInputs)
    }

    private func tabKey(_ tabID: String) -> String {
        session.selectedProject.path + "|tab." + tabID
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
        static let tabInputs = "configActions.tabInputs"
        static let recentInputs = "configActions.recentInputs"
        static let copyHistory = "configActions.copyHistory"
    }

    private enum Limits {
        static let copyHistory = 30
        static let recentValues = 12
    }
}
