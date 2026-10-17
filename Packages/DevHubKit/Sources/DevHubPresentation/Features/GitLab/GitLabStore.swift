import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class GitLabStore {
    private(set) var requests: [MergeRequestSummary] = []
    private(set) var username: String?
    private(set) var error: MergeRequestError?
    private(set) var isLoading = false
    private(set) var loadedQuery: MergeRequestQuery?
    private(set) var busyIDs: Set<MergeRequestSummary.ID> = []
    private(set) var seenAt: Date?
    private(set) var revealedID: MergeRequestSummary.ID?
    private(set) var nextCursor: String?
    private(set) var isLoadingMore = false
    var expandedID: MergeRequestSummary.ID?
    var scope: MergeRequestScope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Self.scopeKey)
            showCachedPage()
        }
    }
    var stateFilter: MergeRequestStateFilter {
        didSet {
            guard stateFilter != oldValue else { return }
            store.set(stateFilter.rawValue, forKey: Self.stateKey)
            showCachedPage()
        }
    }
    var filter: MergeRequestFilter {
        didSet {
            guard filter != oldValue else { return }
            store.encode(filter, forKey: Self.filterKey)
        }
    }
    var listStyle: MergeRequestListStyle {
        didSet {
            guard listStyle != oldValue else { return }
            store.set(listStyle.rawValue, forKey: Self.listStyleKey)
        }
    }
    var listFraction: Double {
        didSet {
            guard listFraction != oldValue else { return }
            store.encode(listFraction, forKey: Self.listFractionKey)
        }
    }

    @ObservationIgnored private let repository: MergeRequestRepository
    @ObservationIgnored private let remote: any GitLabRemoteLookup
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var pages: [MergeRequestQuery: CachedPage] = [:]

    private static let staleAfter: TimeInterval = 60

    private static let scopeKey = "gitlab.scope"
    private static let stateKey = "gitlab.state"
    private static let filterKey = "gitlab.filter"
    private static let listStyleKey = "gitlab.listStyle"
    private static let listFractionKey = "gitlab.listFraction"

    private static func seenKey(_ scope: MergeRequestScope) -> String {
        "gitlab.seenAt.\(scope.rawValue)"
    }

    init(repository: MergeRequestRepository, remote: any GitLabRemoteLookup, activity: ActivityLog, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.remote = remote
        self.store = store
        self.activity = activity
        self.events = events
        scope = store.string(forKey: Self.scopeKey).flatMap(MergeRequestScope.init(rawValue:)) ?? .mine
        stateFilter = store.string(forKey: Self.stateKey).flatMap(MergeRequestStateFilter.init(rawValue:)) ?? .opened
        filter = store.decode(MergeRequestFilter.self, forKey: Self.filterKey) ?? MergeRequestFilter()
        listStyle = store.string(forKey: Self.listStyleKey).flatMap(MergeRequestListStyle.init(rawValue:)) ?? .detailed
        listFraction = store.decode(Double.self, forKey: Self.listFractionKey) ?? Double(GitLabLayout.defaultListFraction)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            requests = []
            username = nil
            error = nil
            loadedQuery = nil
            loadedAt = nil
            expandedID = nil
            pages = [:]
            nextCursor = nil
        }
    }

    var query: MergeRequestQuery {
        MergeRequestQuery(scope: scope, state: scope == .reviewing ? .opened : stateFilter)
    }

    var hasLoaded: Bool {
        loadedQuery == query
    }

    var visible: [MergeRequestSummary] {
        MergeRequestFilterPolicy.apply(filter, to: scopedRequests)
    }

    var filterOptions: MergeRequestFilterOptions {
        MergeRequestFilterPolicy.options(in: scopedRequests, keeping: filter)
    }

    func request(id: MergeRequestSummary.ID) -> MergeRequestSummary? {
        requests.first { $0.id == id }
    }

    func removeFilter(_ kind: MergeRequestFilterChipModel.Kind) {
        switch kind {
        case .targetBranch: filter.targetBranch = nil
        case .label: filter.label = nil
        case .onlyConflicts: filter.onlyConflicts = false
        case .onlyReady: filter.onlyReady = false
        }
    }

    func clearFilter() {
        filter = MergeRequestFilter()
    }

    func isBusy(_ id: MergeRequestSummary.ID) -> Bool {
        busyIDs.contains(id)
    }

    func perform(_ kind: MergeRequestActionModel.Kind, on id: MergeRequestSummary.ID) {
        switch kind {
        case .approve:
            run(id, done: "Approved !\(id)", failed: "Cannot approve !\(id)") { [repository] in
                try await repository.approve(iid: id, repository: $0)
            }
        case .unapprove:
            run(id, done: "Revoked the approval of !\(id)", failed: "Cannot revoke the approval of !\(id)") { [repository] in
                try await repository.unapprove(iid: id, repository: $0)
            }
        case .markReady:
            run(id, done: "Marked !\(id) as ready", failed: "Cannot mark !\(id) as ready") { [repository] in
                try await repository.setDraft(iid: id, isDraft: false, repository: $0)
            }
        case .markDraft:
            run(id, done: "Marked !\(id) as draft", failed: "Cannot mark !\(id) as draft") { [repository] in
                try await repository.setDraft(iid: id, isDraft: true, repository: $0)
            }
        case .rebase:
            run(id, done: "Rebase of !\(id) started", failed: "Cannot rebase !\(id)") { [repository] in
                try await repository.rebase(iid: id, repository: $0)
            }
        case .retryPipeline:
            guard let pipelineID = request(id: id)?.pipeline?.id else { return }
            run(id, done: "Pipeline of !\(id) retried", failed: "Cannot retry the pipeline of !\(id)") { [repository] in
                try await repository.retryPipeline(id: pipelineID, repository: $0)
            }
        case .merge, .mergeWhenPipelinePasses:
            let request = request(id: id)
            merge(id, kind: kind, squash: request?.squashOnMerge ?? true, removeSourceBranch: request?.removesSourceBranch ?? true)
        case .cancelAutoMerge:
            run(id, done: "Cancelled the auto-merge of !\(id)", failed: "Cannot cancel the auto-merge of !\(id)") { [repository] in
                try await repository.cancelAutoMerge(iid: id, repository: $0)
            }
        case .cancelPipeline:
            guard let pipelineID = request(id: id)?.pipeline?.id else { return }
            run(id, done: "Pipeline of !\(id) cancelled", failed: "Cannot cancel the pipeline of !\(id)") { [repository] in
                try await repository.cancelPipeline(id: pipelineID, repository: $0)
            }
        }
    }

    func merge(_ id: MergeRequestSummary.ID, kind: MergeRequestActionModel.Kind, squash: Bool, removeSourceBranch: Bool) {
        guard kind == .mergeWhenPipelinePasses else {
            run(id, done: "Merged !\(id)", failed: "Cannot merge !\(id)") { [repository] in
                try await repository.merge(iid: id, squash: squash, removeSourceBranch: removeSourceBranch, repository: $0)
            }
            return
        }
        guard let sha = request(id: id)?.headSHA else {
            activity.log("Cannot set auto-merge for !\(id)", detail: "GitLab did not send the last commit of the request. Refresh and try again.", outcome: .failure)
            return
        }
        run(id, done: "!\(id) merges when the pipeline passes", failed: "Cannot set auto-merge for !\(id)") { [repository] in
            try await repository.setAutoMerge(iid: id, sha: sha, squash: squash, removeSourceBranch: removeSourceBranch, repository: $0)
        }
    }

    private func run(_ id: MergeRequestSummary.ID, done: String, failed: String, _ work: @escaping @Sendable (URL) async throws -> Void) {
        guard busyIDs.contains(id) == false else { return }
        busyIDs.insert(id)
        let detail = request(id: id)?.title ?? ""
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.gitLabURL()
                try await work(url)
                activity.log(done, detail: detail, outcome: .success)
                events.post(.mergeRequestsChanged)
            } catch {
                activity.log(failed, detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
            await refresh()
        }
    }

    func beginVisit(now: Date) {
        let key = Self.seenKey(scope)
        seenAt = store.decode(Date.self, forKey: key)
        store.encode(now, forKey: key)
    }

    func reveal(_ id: MergeRequestSummary.ID) async {
        if visible.contains(where: { $0.id == id }) == false {
            filter = MergeRequestFilter()
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
            let url = try await remote.gitLabURL()
            let page = try await repository.list(query, after: cursor, repository: url)
            guard query == self.query, cursor == nextCursor else { return }
            let known = Set(requests.map(\.id))
            requests += page.requests.filter { known.contains($0.id) == false }
            nextCursor = page.hasNextPage ? page.endCursor : nil
            rememberPage(query)
        } catch {
            activity.log("Cannot read more merge requests", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func toggleExpanded(_ id: MergeRequestSummary.ID) {
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
                let url = try await remote.gitLabURL()
                let loaded = try await repository.list(query, after: nil, repository: url)
                try Task.checkCancellation()
                if loaded.requests != requests {
                    requests = loaded.requests
                }
                let cursor = loaded.hasNextPage ? loaded.endCursor : nil
                if nextCursor != cursor {
                    nextCursor = cursor
                }
                if username != loaded.username {
                    username = loaded.username
                }
                if error != nil {
                    error = nil
                }
                loadedAt = .now
                loggedError = nil
                rememberPage(query)
            } catch let failure as MergeRequestError {
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
        guard let page = pages[query] else {
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

    private func rememberPage(_ query: MergeRequestQuery) {
        guard let username, let loadedAt else { return }
        pages[query] = CachedPage(requests: requests, username: username, nextCursor: nextCursor, loadedAt: loadedAt)
    }

    private func report(_ failure: MergeRequestError) {
        error = failure
        loadedAt = nil
        if case .notGitLab = failure { return }
        let message = failure.localizedDescription
        guard message != loggedError else { return }
        loggedError = message
        activity.log("Cannot read merge requests", detail: message, outcome: .failure)
    }

    private var scopedRequests: [MergeRequestSummary] {
        guard scope == .reviewing, let username else { return requests }
        return requests.filter { ReviewQueuePolicy.needsMyReview($0, username: username) }
    }
}

private struct CachedPage {
    let requests: [MergeRequestSummary]
    let username: String
    let nextCursor: String?
    let loadedAt: Date
}
