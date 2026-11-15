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
    private(set) var readAt: Date?
    private(set) var limit = TrackerQueryPolicy.pageSize
    private(set) var starred: [String] = []
    private(set) var busyKeys: Set<String> = []
    private(set) var expandedKey: String?
    private(set) var details: [String: TrackerIssueDetails] = [:]
    private(set) var loadingDetails: Set<String> = []
    private(set) var detailErrors: [String: String] = [:]
    var scope: IssueScope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Keys.scope)
            showCached()
            Task { await refresh() }
        }
    }
    var order: IssueOrder {
        didSet {
            guard order != oldValue else { return }
            store.set(order.rawValue, forKey: Keys.order)
            showCached()
            Task { await refresh() }
        }
    }
    var includesDone: Bool {
        didSet {
            guard includesDone != oldValue else { return }
            store.set(includesDone, forKey: Keys.includesDone)
            showCached()
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
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var lists = TrackerCache<[TrackerIssue]>()
    @ObservationIgnored private var detailsCache = TrackerCache<TrackerIssueDetails>()
    @ObservationIgnored private var shownView: String?

    static let listCacheLimit = 8
    static let detailsCacheLimit = 30

    private enum Keys {
        static let scope = "utils.tickets.scope"
        static let order = "utils.tickets.order"
        static let includesDone = "utils.tickets.includesDone"
        static let grouping = "utils.tickets.grouping"
        static let hiddenTypes = "utils.tickets.hiddenTypes"
        static let tool = "utils.tickets.tool"
        static let toolVersion = "version"
        static let toolUser = "user"

        static func starred(_ project: String) -> String {
            "utils.tickets.starred.\(project)"
        }

        static func lists(_ project: String) -> String {
            "utils.tickets.cache.lists.\(project)"
        }

        static func details(_ project: String) -> String {
            "utils.tickets.cache.details.\(project)"
        }
    }

    init(repository: any IssueTrackerRepository, config: ConfigStore, activity: ActivityLog, toaster: Toaster, events: AppEvents, store: any KeyValueStore, now: @escaping () -> Date) {
        self.repository = repository
        self.config = config
        self.activity = activity
        self.toaster = toaster
        self.store = store
        self.now = now
        scope = store.string(forKey: Keys.scope).flatMap(IssueScope.init(rawValue:)) ?? .mine
        order = store.string(forKey: Keys.order).flatMap(IssueOrder.init(rawValue:)) ?? .updated
        includesDone = store.bool(forKey: Keys.includesDone)
        grouping = store.string(forKey: Keys.grouping).flatMap(TicketGrouping.init(rawValue:)) ?? .status
        hiddenTypes = Set(store.strings(forKey: Keys.hiddenTypes) ?? [])
        if let saved = store.stringMap(forKey: Keys.tool) {
            toolState = .ready(version: saved[Keys.toolVersion], user: saved[Keys.toolUser])
        }
        restore()
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                clear()
            case .configChanged:
                clear()
                restore()
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

    var canWatch: Bool {
        user != nil
    }

    var canLoadMore: Bool {
        issues.count >= limit && limit < TrackerQueryPolicy.maxPageSize
    }

    var pinnedKeys: [String] {
        scope == .starred ? [] : starred
    }

    func isShown(_ issue: TrackerIssue) -> Bool {
        hiddenTypes.contains(issue.type) == false
    }

    func isStarred(_ key: String) -> Bool {
        starred.contains(key)
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

    func toggleStar(_ key: String) {
        if let index = starred.firstIndex(of: key) {
            starred.remove(at: index)
        } else {
            starred.append(key)
        }
        store.set(starred, forKey: Keys.starred(project))
        guard scope == .starred else { return }
        issues.removeAll { starred.contains($0.key) == false }
        shownView = viewKey
        Task { await refresh() }
    }

    func loadMore() {
        guard canLoadMore else { return }
        limit = TrackerQueryPolicy.maxPageSize
        Task { await refresh() }
    }

    func refresh() async {
        await read(checksTool: false)
    }

    func reload() async {
        await read(checksTool: true)
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
            detailsCache.save(loaded, for: key, at: now(), limit: Self.detailsCacheLimit)
            store.encode(detailsCache, forKey: Keys.details(project))
        } catch {
            detailErrors[key] = error.localizedDescription
            activity.log("Cannot read \(key)", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func move(_ key: String, to status: String) {
        perform(
            key,
            title: "Moved \(key) to \(status)",
            detail: "jira issue move \(key) \"\(status)\"",
            toast: "\(key) is now \(status)",
            failure: "Could not move \(key) to \(status)",
            readsDetails: false
        ) { [repository] in
            try await repository.transition(key: key, to: status)
        }
    }

    func start(_ key: String) {
        move(key, to: settings.startStatus)
    }

    func assignToMe(_ key: String) {
        guard let user else { return }
        perform(
            key,
            title: "Assigned \(key) to you",
            detail: "jira issue assign \(key) \(user)",
            toast: "\(key) is now assigned to you",
            failure: "Could not assign \(key)",
            readsDetails: false
        ) { [repository] in
            try await repository.assign(key: key, to: user)
        }
    }

    func unassign(_ key: String) {
        perform(
            key,
            title: "Removed the assignee of \(key)",
            detail: "jira issue assign \(key) x",
            toast: "\(key) has no assignee now",
            failure: "Could not unassign \(key)",
            readsDetails: false
        ) { [repository] in
            try await repository.unassign(key: key)
        }
    }

    func watch(_ key: String) {
        guard let user else { return }
        perform(
            key,
            title: "Watching \(key)",
            detail: "jira issue watch \(key) \(user)",
            toast: "You now watch \(key)",
            failure: "Could not watch \(key)",
            readsDetails: true
        ) { [repository] in
            try await repository.watch(key: key, user: user)
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

    private var project: String {
        settings.project ?? ""
    }

    private var jql: String? {
        TrackerQueryPolicy.jql(for: scope, includesDone: includesDone, settings: settings, starred: starred)
    }

    private var viewKey: String {
        "\(order.rawValue)|\(jql ?? "")"
    }

    private func clear() {
        issues = []
        error = nil
        readAt = nil
        expandedKey = nil
        details = [:]
        detailErrors = [:]
        shownView = nil
    }

    private func restore() {
        starred = store.strings(forKey: Keys.starred(project)) ?? []
        lists = store.decode(TrackerCache<[TrackerIssue]>.self, forKey: Keys.lists(project)) ?? TrackerCache()
        detailsCache = store.decode(TrackerCache<TrackerIssueDetails>.self, forKey: Keys.details(project)) ?? TrackerCache()
        details = detailsCache.values
        shownView = nil
        showCached()
    }

    private func showCached() {
        let key = viewKey
        guard key != shownView else { return }
        shownView = key
        let entry = lists.entry(for: key)
        issues = entry?.value ?? []
        readAt = entry?.readAt
        limit = issues.count > TrackerQueryPolicy.pageSize ? TrackerQueryPolicy.maxPageSize : TrackerQueryPolicy.pageSize
        error = nil
    }

    private func read(checksTool: Bool) async {
        guard isEnabled else {
            issues = []
            return
        }
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer { isLoading = false }
            showCached()
            let skipsCheck = checksTool == false && isReady
            if skipsCheck == false {
                guard try await checkTool() else { return }
            }
            guard let jql else {
                issues = []
                error = nil
                return
            }
            let settings = settings
            let key = viewKey
            do {
                let loaded = try await repository.issues(jql: jql, project: settings.project, order: order, limit: limit)
                try Task.checkCancellation()
                if loaded != issues {
                    issues = loaded
                }
                error = nil
                let date = now()
                readAt = date
                lists.save(loaded, for: key, at: date, limit: Self.listCacheLimit)
                store.encode(lists, forKey: Keys.lists(project))
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
                activity.log("Cannot read tickets", detail: error.localizedDescription, outcome: .failure)
                if skipsCheck {
                    _ = try await checkTool()
                }
            }
        }
    }

    private func checkTool() async throws -> Bool {
        let state = await repository.toolState()
        try Task.checkCancellation()
        if state != toolState {
            toolState = state
        }
        saveTool(state)
        guard state.isReady else {
            issues = []
            readAt = nil
            return false
        }
        return true
    }

    private func saveTool(_ state: TrackerToolState) {
        guard case .ready(let version, let user) = state else {
            store.remove(forKey: Keys.tool)
            return
        }
        var saved: [String: String] = [:]
        saved[Keys.toolVersion] = version
        saved[Keys.toolUser] = user
        store.set(saved, forKey: Keys.tool)
    }

    private func perform(_ key: String, title: String, detail: String, toast: String, failure: String, readsDetails: Bool, action: @escaping @Sendable () async throws -> Void) {
        guard busyKeys.contains(key) == false else { return }
        busyKeys.insert(key)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await action()
                busyKeys.remove(key)
                activity.log(title, detail: detail, outcome: .success)
                toaster.show(toast)
                if readsDetails {
                    await loadDetails(key)
                }
                await refresh()
            } catch {
                busyKeys.remove(key)
                activity.log(failure, detail: error.localizedDescription, outcome: .failure)
                toaster.show("\(failure): \(error.localizedDescription)")
            }
        }
    }
}
