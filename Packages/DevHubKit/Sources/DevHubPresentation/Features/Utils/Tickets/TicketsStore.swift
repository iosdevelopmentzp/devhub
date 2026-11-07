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
    var scope: IssueScope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Keys.scope)
            Task { await refresh() }
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
    }

    init(repository: any IssueTrackerRepository, config: ConfigStore, activity: ActivityLog, toaster: Toaster, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.config = config
        self.activity = activity
        self.toaster = toaster
        self.store = store
        scope = store.string(forKey: Keys.scope).flatMap(IssueScope.init(rawValue:)) ?? .mine
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                issues = []
                error = nil
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
                let loaded = try await repository.issues(jql: TrackerQueryPolicy.jql(for: scope, settings: settings), project: settings.project, limit: TrackerQueryPolicy.pageSize)
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

    func branchName(for issue: TrackerIssue) -> String {
        TrackerBranchPolicy.branchName(for: issue, format: settings.branchFormat)
    }
}
