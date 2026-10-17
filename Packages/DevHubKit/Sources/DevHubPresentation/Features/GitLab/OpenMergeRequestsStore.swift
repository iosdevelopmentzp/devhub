import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class OpenMergeRequestsStore {
    private(set) var requestsByBranch: [String: MergeRequestSummary] = [:]
    private(set) var reviewCount = 0
    private(set) var username: String?

    @ObservationIgnored private let repository: MergeRequestRepository
    @ObservationIgnored private let remote: any GitLabRemoteLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var hasReportedCap = false
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let staleAfter: TimeInterval = 60
    private static let pollInterval: Duration = .seconds(300)

    init(repository: MergeRequestRepository, remote: any GitLabRemoteLookup, activity: ActivityLog, events: AppEvents) {
        self.repository = repository
        self.remote = remote
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                requestsByBranch = [:]
                reviewCount = 0
                loadedAt = nil
                hasReportedCap = false
                Task { await self.refresh() }
            case .mergeRequestsChanged:
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    func request(forBranch branch: String) -> MergeRequestSummary? {
        requestsByBranch[BranchName(branch, remote: remote.remoteName).local]
    }

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await refresh()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    func refreshIfStale() async {
        if let loadedAt, loadedAt.timeIntervalSinceNow > -Self.staleAfter { return }
        await refresh()
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.gitLabURL()
                let loaded = try await repository.openRequests(repository: url)
                try Task.checkCancellation()
                apply(loaded)
            } catch is CancellationError {
            } catch MergeRequestError.notGitLab {
            } catch {
                report(error)
            }
        }
    }

    private func apply(_ loaded: MergeRequestList) {
        let byBranch = Dictionary(loaded.requests.map { ($0.sourceBranch, $0) }, uniquingKeysWith: { first, _ in first })
        if byBranch != requestsByBranch {
            requestsByBranch = byBranch
        }
        if username != loaded.username {
            username = loaded.username
        }
        let count = ReviewQueuePolicy.count(in: loaded.requests, username: loaded.username)
        if count != reviewCount {
            reviewCount = count
        }
        loadedAt = .now
        loggedError = nil
        if loaded.totalCount > loaded.requests.count, hasReportedCap == false {
            hasReportedCap = true
            activity.log(
                "GitLab has \(loaded.totalCount) open merge requests, DevHub reads \(loaded.requests.count)",
                detail: "Branch tags and the review count can miss the rest",
                outcome: .info
            )
        }
    }

    private func report(_ error: Error) {
        let message = error.localizedDescription
        guard message != loggedError else { return }
        loggedError = message
        activity.log("Cannot read open merge requests", detail: message, outcome: .failure)
    }
}
