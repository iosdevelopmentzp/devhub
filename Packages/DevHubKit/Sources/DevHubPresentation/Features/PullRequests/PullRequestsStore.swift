import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class PullRequestsStore {
    private(set) var requests: [PullRequestSummary] = []
    private(set) var username: String?
    private(set) var error: PullRequestError?
    private(set) var isLoading = false
    private(set) var loadedQuery: PullRequestQuery?
    private(set) var busyIDs: Set<PullRequestSummary.ID> = []
    private(set) var seenAt: Date?
    private(set) var revealedID: PullRequestSummary.ID?
    private(set) var nextCursor: String?
    private(set) var isLoadingMore = false
    var expandedID: PullRequestSummary.ID?
    var scope: PullRequestScope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: PullRequestsPreferenceKeys.scope)
            showCachedPage()
        }
    }
    var stateFilter: PullRequestStateFilter {
        didSet {
            guard stateFilter != oldValue else { return }
            store.set(stateFilter.rawValue, forKey: PullRequestsPreferenceKeys.state)
            showCachedPage()
        }
    }
    var filter: PullRequestFilter {
        didSet {
            guard filter != oldValue else { return }
            store.encode(filter, forKey: PullRequestsPreferenceKeys.filter)
        }
    }
    var listStyle: PullRequestListStyle {
        didSet {
            guard listStyle != oldValue else { return }
            store.set(listStyle.rawValue, forKey: PullRequestsPreferenceKeys.listStyle)
        }
    }
    var listFraction: Double {
        didSet {
            guard listFraction != oldValue else { return }
            store.encode(listFraction, forKey: PullRequestsPreferenceKeys.listFraction)
        }
    }

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var cache = PullRequestListCache()

    private static let staleAfter: TimeInterval = 60

    var words: CodeHostWords {
        remote.words
    }

    init(repository: CodeHostRepository, remote: any CodeHostLookup, activity: ActivityLog, operations: OperationLog, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.remote = remote
        self.store = store
        self.activity = activity
        self.operations = operations
        self.events = events
        scope = store.string(forKey: PullRequestsPreferenceKeys.scope).flatMap(PullRequestScope.init(rawValue:)) ?? .mine
        stateFilter = store.string(forKey: PullRequestsPreferenceKeys.state).flatMap(PullRequestStateFilter.init(rawValue:)) ?? .opened
        filter = store.decode(PullRequestFilter.self, forKey: PullRequestsPreferenceKeys.filter) ?? PullRequestFilter()
        listStyle = store.string(forKey: PullRequestsPreferenceKeys.listStyle).flatMap(PullRequestListStyle.init(rawValue:)) ?? .detailed
        listFraction = store.decode(Double.self, forKey: PullRequestsPreferenceKeys.listFraction) ?? Double(PullRequestsLayout.defaultListFraction)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                requests = []
                username = nil
                error = nil
                loadedQuery = nil
                loadedAt = nil
                expandedID = nil
                cache.clear()
                nextCursor = nil
            case .refreshRequested(.pullRequests):
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    var query: PullRequestQuery {
        PullRequestQuery(scope: scope, state: scope == .reviewing ? .opened : stateFilter)
    }

    var hasLoaded: Bool {
        loadedQuery == query
    }

    func request(id: PullRequestSummary.ID) -> PullRequestSummary? {
        requests.first { $0.id == id }
    }

    func isBusy(_ id: PullRequestSummary.ID) -> Bool {
        busyIDs.contains(id)
    }

    func perform(_ kind: PullRequestActionModel.Kind, on id: PullRequestSummary.ID) {
        let pipelineID = request(id: id)?.pipeline?.id
        switch kind {
        case .approve:
            run(id, kind) { [repository] in try await repository.approve(iid: id, repository: $0) }
        case .unapprove:
            run(id, kind) { [repository] in try await repository.unapprove(iid: id, repository: $0) }
        case .markReady:
            run(id, kind) { [repository] in try await repository.setDraft(iid: id, isDraft: false, repository: $0) }
        case .markDraft:
            run(id, kind) { [repository] in try await repository.setDraft(iid: id, isDraft: true, repository: $0) }
        case .rebase:
            run(id, kind) { [repository] in try await repository.rebase(iid: id, repository: $0) }
        case .retryPipeline:
            guard let pipelineID else { return }
            run(id, kind) { [repository] in try await repository.retryPipeline(id: pipelineID, repository: $0) }
        case .cancelPipeline:
            guard let pipelineID else { return }
            run(id, kind) { [repository] in try await repository.cancelPipeline(id: pipelineID, repository: $0) }
        case .cancelAutoMerge:
            run(id, kind) { [repository] in try await repository.cancelAutoMerge(iid: id, repository: $0) }
        case .merge, .mergeWhenPipelinePasses:
            let request = request(id: id)
            merge(id, kind: kind, squash: request?.squashOnMerge ?? true, removeSourceBranch: request?.removesSourceBranch ?? true)
        }
    }

    func merge(_ id: PullRequestSummary.ID, kind: PullRequestActionModel.Kind, squash: Bool, removeSourceBranch: Bool) {
        guard kind == .mergeWhenPipelinePasses else {
            run(id, kind) { [repository] in try await repository.merge(iid: id, squash: squash, removeSourceBranch: removeSourceBranch, repository: $0) }
            return
        }
        guard let sha = request(id: id)?.headSHA else {
            activity.log("Cannot set auto-merge for \(remote.words.reference(id))", detail: "\(remote.words.hostTitle) did not send the last commit of the request. Refresh and try again.", outcome: .failure)
            return
        }
        run(id, kind) { [repository] in try await repository.setAutoMerge(iid: id, sha: sha, squash: squash, removeSourceBranch: removeSourceBranch, repository: $0) }
    }

    private func run(_ id: PullRequestSummary.ID, _ kind: PullRequestActionModel.Kind, _ work: @escaping @Sendable (CodeHost) async throws -> Void) {
        guard busyIDs.contains(id) == false else { return }
        let texts = PullRequestActionTexts.texts(for: kind, number: id, words: remote.words)
        busyIDs.insert(id)
        let detail = request(id: id)?.title ?? ""
        let retry: () -> Void = { [weak self] in
            guard let self else { return }
            run(id, kind, work)
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(texts.title, at: .pullRequest(id), retry: retry) {
                    let url = try await remote.codeHost()
                    try await work(url)
                }
                activity.log(texts.done, detail: detail, outcome: .success)
                events.post(.pullRequestsChanged)
                if kind == .approve {
                    events.post(.pullRequestReviewed(iid: id))
                }
            } catch {
                activity.log(texts.failed, detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
            await refresh()
        }
    }

    func beginVisit(now: Date) {
        let key = PullRequestsPreferenceKeys.seenAt(scope)
        seenAt = store.decode(Date.self, forKey: key)
        store.encode(now, forKey: key)
    }

    func reveal(_ id: PullRequestSummary.ID) async {
        if visible.contains(where: { $0.id == id }) == false {
            filter = PullRequestFilter()
            scope = .all
            stateFilter = .opened
            await refresh()
            if request(id: id) == nil {
                stateFilter = .all
                await refresh()
            }
        }
        expandedID = id
        revealedID = id
    }

    var hasMore: Bool {
        nextCursor != nil
    }

    func loadMore() async {
        guard let cursor = nextCursor, isLoadingMore == false else { return }
        let query = query
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let url = try await remote.codeHost()
            let page = try await repository.list(query, after: cursor, repository: url)
            guard query == self.query, cursor == nextCursor else { return }
            let known = Set(requests.map(\.id))
            requests += page.requests.filter { known.contains($0.id) == false }
            nextCursor = page.hasNextPage ? page.endCursor : nil
            rememberPage(query)
        } catch {
            activity.log("Cannot read more \(remote.words.requests)", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func toggleExpanded(_ id: PullRequestSummary.ID) {
        expandedID = expandedID == id ? nil : id
    }

    func refreshIfStale() async {
        if hasLoaded, let loadedAt, loadedAt.timeIntervalSinceNow > -Self.staleAfter { return }
        await refresh()
    }

    func refresh() async {
        let query = query
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer {
                if Task.isCancelled == false {
                    isLoading = false
                }
            }
            if loadedQuery != query, requests.isEmpty == false {
                requests = []
            }
            do {
                let url = try await remote.codeHost()
                let loaded = try await repository.list(query, after: nil, repository: url)
                try Task.checkCancellation()
                update(\.requests, loaded.requests)
                update(\.nextCursor, loaded.hasNextPage ? loaded.endCursor : nil)
                update(\.username, loaded.username)
                update(\.error, nil)
                loadedAt = .now
                loggedError = nil
                rememberPage(query)
            } catch let failure as PullRequestError {
                try Task.checkCancellation()
                report(failure)
            } catch {
                try Task.checkCancellation()
                report(.command(error.localizedDescription))
            }
            loadedQuery = query
        }
    }

    private func showCachedPage() {
        let query = query
        guard loadedQuery != query else { return }
        guard let page = cache.page(for: query) else {
            requests = []
            nextCursor = nil
            loadedQuery = nil
            loadedAt = nil
            return
        }
        requests = page.requests
        username = page.username
        nextCursor = page.nextCursor
        loadedAt = page.loadedAt
        error = nil
        loadedQuery = query
    }

    private func rememberPage(_ query: PullRequestQuery) {
        guard let username, let loadedAt else { return }
        cache.remember(PullRequestListCache.Page(requests: requests, username: username, nextCursor: nextCursor, loadedAt: loadedAt), for: query)
    }

    private func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<PullRequestsStore, Value>, _ value: Value) {
        guard self[keyPath: keyPath] != value else { return }
        self[keyPath: keyPath] = value
    }

    private func report(_ failure: PullRequestError) {
        error = failure
        loadedAt = nil
        if case .noCodeHost = failure { return }
        let message = failure.localizedDescription
        guard message != loggedError else { return }
        loggedError = message
        activity.log("Cannot read \(remote.words.requests)", detail: message, outcome: .failure)
    }
}

