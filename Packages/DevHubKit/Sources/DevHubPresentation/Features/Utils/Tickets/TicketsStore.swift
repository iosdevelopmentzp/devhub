import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class TicketsStore {
    private(set) var issues: [TrackerIssue] = []
    private(set) var toolState: TrackerToolState?
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var busyKeys: Set<String> = []
    private(set) var expandedKey: String?
    private(set) var details: [String: TrackerIssueDetails] = [:]
    private(set) var loadingDetails: Set<String> = []
    private(set) var detailErrors: [String: String] = [:]
    var scope: IssueScope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Keys.scope)
            Task { await refresh() }
        }
    }
    var order: IssueOrder {
        didSet {
            guard order != oldValue else { return }
            store.set(order.rawValue, forKey: Keys.order)
            Task { await refresh() }
        }
    }
    var includesDone: Bool {
        didSet {
            guard includesDone != oldValue else { return }
            store.set(includesDone, forKey: Keys.includesDone)
            Task { await refresh() }
        }
    }
    var grouping: TicketGrouping {
        didSet {
            guard grouping != oldValue else { return }
            store.set(grouping.rawValue, forKey: Keys.grouping)
        }
    }
    var hiddenTypes: Set<String> {
        didSet {
            guard hiddenTypes != oldValue else { return }
            store.set(hiddenTypes.sorted(), forKey: Keys.hiddenTypes)
        }
    }

    @ObservationIgnored private let repository: any IssueTrackerRepository
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let toaster: Toaster
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    private enum Keys {
        static let scope = "utils.tickets.scope"
        static let order = "utils.tickets.order"
        static let includesDone = "utils.tickets.includesDone"
        static let grouping = "utils.tickets.grouping"
        static let hiddenTypes = "utils.tickets.hiddenTypes"
    }

    init(repository: any IssueTrackerRepository, config: ConfigStore, activity: ActivityLog, toaster: Toaster, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.config = config
        self.activity = activity
        self.toaster = toaster
        self.store = store
        scope = store.string(forKey: Keys.scope).flatMap(IssueScope.init(rawValue:)) ?? .mine
        order = store.string(forKey: Keys.order).flatMap(IssueOrder.init(rawValue:)) ?? .updated
        includesDone = store.bool(forKey: Keys.includesDone)
        grouping = store.string(forKey: Keys.grouping).flatMap(TicketGrouping.init(rawValue:)) ?? .status
        hiddenTypes = Set(store.strings(forKey: Keys.hiddenTypes) ?? [])
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                issues = []
                error = nil
                expandedKey = nil
                details = [:]
                detailErrors = [:]
            default:
                break
            }
        }
    }

    var settings: TrackerSettings {
        TrackerSettingsPolicy.settings(for: config.config)
    }

    var isEnabled: Bool {
        settings.kind != .disabled
    }

    var isReady: Bool {
        toolState?.isReady == true
    }

    var user: String? {
        guard case .ready(_, let user) = toolState else { return nil }
        return user
    }

    var types: [String] {
        Set(issues.map(\.type).filter { $0.isEmpty == false }).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var isFiltered: Bool {
        includesDone || hiddenTypes.isEmpty == false
    }

    var isDefaultView: Bool {
        isFiltered == false && grouping == .status && order == .updated
    }

    var canAssignToMe: Bool {
        user != nil && scope != .mine
    }

    func isShown(_ issue: TrackerIssue) -> Bool {
        hiddenTypes.contains(issue.type) == false
    }

    func toggleType(_ type: String) {
        if hiddenTypes.contains(type) {
            hiddenTypes.remove(type)
        } else {
            hiddenTypes.insert(type)
        }
    }

    func resetView() {
        grouping = .status
        order = .updated
        includesDone = false
        hiddenTypes = []
    }

    func refresh() async {
        guard isEnabled else {
            issues = []
            return
        }
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            let state = await repository.toolState()
            try Task.checkCancellation()
            if state != toolState {
                toolState = state
            }
            guard state.isReady else {
                issues = []
                return
            }
            let settings = settings
            do {
                let loaded = try await repository.issues(
                    jql: TrackerQueryPolicy.jql(for: scope, includesDone: includesDone, settings: settings),
                    project: settings.project,
                    order: order,
                    limit: TrackerQueryPolicy.pageSize
                )
                try Task.checkCancellation()
                if loaded != issues {
                    issues = loaded
                }
                error = nil
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
                activity.log("Cannot read tickets", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func toggleDetails(_ key: String) {
        guard expandedKey != key else {
            expandedKey = nil
            return
        }
        expandedKey = key
        Task { await loadDetails(key) }
    }

    func loadDetails(_ key: String) async {
        guard loadingDetails.contains(key) == false else { return }
        loadingDetails.insert(key)
        detailErrors[key] = nil
        defer { loadingDetails.remove(key) }
        do {
            let loaded = try await repository.details(key: key)
            if details[key] != loaded {
                details[key] = loaded
            }
        } catch {
            detailErrors[key] = error.localizedDescription
            activity.log("Cannot read \(key)", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func move(_ key: String, to status: String) {
        guard busyKeys.contains(key) == false else { return }
        busyKeys.insert(key)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.transition(key: key, to: status)
                busyKeys.remove(key)
                activity.log("Moved \(key) to \(status)", detail: "jira issue move \(key) \"\(status)\"", outcome: .success)
                toaster.show("\(key) is now \(status)")
                await refresh()
            } catch {
                busyKeys.remove(key)
                activity.log("Could not move \(key) to \(status)", detail: error.localizedDescription, outcome: .failure)
                toaster.show("Could not move \(key): \(error.localizedDescription)")
            }
        }
    }

    func start(_ key: String) {
        move(key, to: settings.startStatus)
    }

    func assignToMe(_ key: String) {
        guard let user, busyKeys.contains(key) == false else { return }
        busyKeys.insert(key)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.assign(key: key, to: user)
                busyKeys.remove(key)
                activity.log("Assigned \(key) to you", detail: "jira issue assign \(key) \(user)", outcome: .success)
                toaster.show("\(key) is now assigned to you")
                await refresh()
            } catch {
                busyKeys.remove(key)
                activity.log("Could not assign \(key)", detail: error.localizedDescription, outcome: .failure)
                toaster.show("Could not assign \(key): \(error.localizedDescription)")
            }
        }
    }

    func comment(_ key: String, text: String) async -> Bool {
        let text = text.trimmed
        guard text.isEmpty == false, busyKeys.contains(key) == false else { return false }
        busyKeys.insert(key)
        defer { busyKeys.remove(key) }
        do {
            try await repository.comment(key: key, text: text)
            activity.log("Commented on \(key)", detail: "jira issue comment add \(key)", outcome: .success)
            toaster.show("Comment added to \(key)")
            await loadDetails(key)
            return true
        } catch {
            activity.log("Could not comment on \(key)", detail: error.localizedDescription, outcome: .failure)
            toaster.show("Could not comment on \(key): \(error.localizedDescription)")
            return false
        }
    }

    func branchName(for issue: TrackerIssue) -> String {
        TrackerBranchPolicy.branchName(for: issue, format: settings.branchFormat)
    }
}
