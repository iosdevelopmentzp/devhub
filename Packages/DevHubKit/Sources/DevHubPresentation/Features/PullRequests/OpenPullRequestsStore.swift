import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class OpenPullRequestsStore: OpenRequestsLookup {
    private(set) var requestsByBranch: [String: PullRequestSummary] = [:]
    private(set) var reviewCount = 0
    private(set) var username: String?
    private(set) var watchedIDs: Set<Int> = []

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var hasReportedCap = false
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let staleAfter: TimeInterval = 60
    private static let panelPollInterval: Duration = .seconds(300)
    private static let closedPanelPollInterval: Duration = .seconds(120)
    private static let watchingPollInterval: Duration = .seconds(60)

    var words: CodeHostWords {
        remote.words
    }

    init(repository: CodeHostRepository, remote: any CodeHostLookup, session: ProjectSession, activity: ActivityLog, notifier: Notifier, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.remote = remote
        self.session = session
        self.activity = activity
        self.notifier = notifier
        self.store = store
        watchedIDs = Self.loadWatched(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                requestsByBranch = [:]
                reviewCount = 0
                loadedAt = nil
                hasReportedCap = false
                watchedIDs = Self.loadWatched(from: store, projectID: session.selectedProjectID)
                Task { await self.refresh() }
            case .pullRequestsChanged:
                Task { await self.refresh(reportingChanges: false) }
            case .refreshRequested(.pullRequests):
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    var requests: [PullRequestSummary] {
        Array(requestsByBranch.values)
    }

    func request(forBranch branch: String) -> PullRequestSummary? {
        requestsByBranch[BranchName(branch, remote: remote.remoteName).local]
    }

    // MARK: Watching

    func isWatched(_ iid: Int) -> Bool {
        watchedIDs.contains(iid)
    }

    func toggleWatch(iid: Int) -> Bool {
        if watchedIDs.contains(iid) {
            watchedIDs.remove(iid)
        } else {
            watchedIDs.insert(iid)
        }
        saveWatched()
        restartPolling()
        return watchedIDs.contains(iid)
    }

    private func unwatch(_ iid: Int) {
        guard watchedIDs.contains(iid) else { return }
        watchedIDs.remove(iid)
        saveWatched()
        restartPolling()
    }

    private func saveWatched() {
        store.encode(watchedIDs.sorted(), forKey: PullRequestsPreferenceKeys.watched(projectID: session.selectedProjectID))
    }

    private static func loadWatched(from store: any KeyValueStore, projectID: String) -> Set<Int> {
        Set(store.decode([Int].self, forKey: PullRequestsPreferenceKeys.watched(projectID: projectID)) ?? [])
    }

    // MARK: Polling

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = poll(refreshingFirst: true)
    }

    static func pollInterval(panelShown: Bool, watching: Bool) -> Duration {
        guard watching == false else { return watchingPollInterval }
        return panelShown ? panelPollInterval : closedPanelPollInterval
    }

    private func restartPolling() {
        guard let pollingTask else { return }
        pollingTask.cancel()
        self.pollingTask = poll(refreshingFirst: false)
    }

    private func poll(refreshingFirst: Bool) -> Task<Void, Never> {
        Task { [weak self] in
            var refreshes = refreshingFirst
            while Task.isCancelled == false {
                guard let self else { return }
                if refreshes {
                    await refresh()
                }
                refreshes = true
                try? await Task.sleep(for: Self.pollInterval(panelShown: notifier.isPanelShown, watching: watchedIDs.isEmpty == false))
            }
        }
    }

    // MARK: Refresh

    func refreshIfStale() async {
        if let loadedAt, loadedAt.timeIntervalSinceNow > -Self.staleAfter { return }
        await refresh()
    }

    func refresh() async {
        await refresh(reportingChanges: true)
    }

    private func refresh(reportingChanges: Bool) async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                let loaded = try await repository.openRequests(repository: url)
                try Task.checkCancellation()
                let changes = loadedAt == nil || reportingChanges == false
                    ? []
                    : OwnRequestChangePolicy.changes(from: Array(requestsByBranch.values), to: loaded.requests, username: loaded.username, watched: watchedIDs)
                apply(loaded)
                report(changes, repository: url)
            } catch is CancellationError {
            } catch PullRequestError.noCodeHost {
            } catch {
                report(error)
            }
        }
    }

    private func report(_ changes: [OwnRequestChange], repository url: CodeHost) {
        for change in changes {
            if case .gone(let request) = change {
                Task { await self.reportGone(request, repository: url) }
                continue
            }
            guard let report = OwnRequestChangeMapper.report(for: change, words: words) else { continue }
            deliver(report, request: change.request)
        }
    }

    private func reportGone(_ request: PullRequestSummary, repository url: CodeHost) async {
        do {
            let status = try await repository.status(branch: request.sourceBranch, repository: url)
            guard let info = status.pullRequest, info.iid == request.iid else { return }
            guard let report = OwnRequestChangeMapper.report(forGone: request, state: info.state, words: words) else { return }
            unwatch(request.iid)
            deliver(report, request: request)
        } catch {
            activity.log("Cannot read \(words.reference(request.iid))", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func deliver(_ report: OwnRequestChangeMapper.Report, request: PullRequestSummary) {
        let kind: NotificationKind = request.author == username ? report.kind : .watched
        activity.log(report.title, detail: report.body, outcome: report.outcome, kind: kind, target: .pullRequest(iid: request.iid))
        notifier.notify(kind, title: report.title, body: report.body, target: .pullRequest(iid: request.iid))
    }

    private func apply(_ loaded: PullRequestList) {
        let byBranch = Dictionary(loaded.requests.map { ($0.sourceBranch, $0) }, uniquingKeysWith: { first, _ in first })
        if byBranch != requestsByBranch {
            requestsByBranch = byBranch
        }
        if username != loaded.username {
            username = loaded.username
        }
        let count = ReviewQueuePolicy.count(in: loaded.requests, username: loaded.username)
        if count != reviewCount {
            if count > reviewCount, loadedAt != nil {
                let title = count == 1 ? "1 \(words.request) waits for your review" : "\(count) \(words.requests) wait for your review"
                activity.log(title, detail: "", outcome: .info, kind: .reviewRequests, target: .reviewQueue)
                notifier.notify(.reviewRequests, title: title, body: nil, target: .reviewQueue)
            }
            reviewCount = count
        }
        loadedAt = .now
        loggedError = nil
        if loaded.totalCount > loaded.requests.count, hasReportedCap == false {
            hasReportedCap = true
            activity.log(
                "\(remote.words.hostTitle) has \(loaded.totalCount) open \(remote.words.requests), DevHub reads \(loaded.requests.count)",
                detail: "Branch tags and the review count can miss the rest",
                outcome: .info
            )
        }
    }

    private func report(_ error: Error) {
        let message = error.localizedDescription
        guard message != loggedError else { return }
        loggedError = message
        activity.log("Cannot read open \(remote.words.requests)", detail: message, outcome: .failure)
    }
}
