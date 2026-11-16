import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class PullRequestSubscriptionsStore {
    private(set) var changes: [Int: Bool] = [:]
    private(set) var busyIDs: Set<Int> = []
    private(set) var isBulkRunning = false
    private(set) var unsubscribedIDs: Set<Int> = []

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let openRequests: any OpenRequestsLookup
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private var subscription: SubscriptionToken?

    var words: CodeHostWords {
        remote.words
    }

    init(
        repository: CodeHostRepository,
        remote: any CodeHostLookup,
        openRequests: any OpenRequestsLookup,
        session: ProjectSession,
        store: any KeyValueStore,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.remote = remote
        self.openRequests = openRequests
        self.session = session
        self.store = store
        self.activity = activity
        self.events = events
        unsubscribedIDs = Self.loadUnsubscribed(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                changes = [:]
                unsubscribedIDs = Self.loadUnsubscribed(from: store, projectID: session.selectedProjectID)
            case .refreshRequested(.pullRequests):
                changes = [:]
            default:
                break
            }
        }
    }

    var othersToUnsubscribe: [PullRequestSummary] {
        PullRequestSubscriptionPolicy.othersToUnsubscribe(openRequests.requests, username: openRequests.username, changes: changes)
    }

    var toSubscribeAgain: [PullRequestSummary] {
        PullRequestSubscriptionPolicy.toSubscribeAgain(openRequests.requests, unsubscribed: unsubscribedIDs, username: openRequests.username, changes: changes)
    }

    func set(_ subscribed: Bool, for request: PullRequestSummary) async -> Bool {
        guard busyIDs.contains(request.iid) == false else { return false }
        busyIDs.insert(request.iid)
        defer { busyIDs.remove(request.iid) }
        return await apply(subscribed, to: [request])
    }

    func unsubscribeOthers() async -> Int? {
        await applyAll(false, to: othersToUnsubscribe)
    }

    func subscribeAgain() async -> Int? {
        await applyAll(true, to: toSubscribeAgain)
    }

    private func applyAll(_ subscribed: Bool, to requests: [PullRequestSummary]) async -> Int? {
        guard isBulkRunning == false, requests.isEmpty == false else { return nil }
        isBulkRunning = true
        defer { isBulkRunning = false }
        guard await apply(subscribed, to: requests) else { return nil }
        return requests.count
    }

    private func apply(_ subscribed: Bool, to requests: [PullRequestSummary]) async -> Bool {
        do {
            let url = try await remote.codeHost()
            try await repository.setSubscribed(subscribed, requests: requests, repository: url)
            remember(subscribed, requests.map(\.iid))
            let subject = subject(of: requests)
            activity.log(subscribed ? "Subscribed to \(subject) on \(words.hostTitle)" : "Unsubscribed from \(subject) on \(words.hostTitle)", detail: references(requests), outcome: .success)
            events.post(.pullRequestsChanged)
            return true
        } catch {
            let subject = subject(of: requests)
            activity.log(subscribed ? "Could not subscribe to \(subject)" : "Could not unsubscribe from \(subject)", detail: error.localizedDescription, outcome: .failure)
            return false
        }
    }

    private func subject(of requests: [PullRequestSummary]) -> String {
        guard requests.count == 1, let request = requests.first else {
            return CountText.count(requests.count, words.request, words.requests)
        }
        return words.reference(request.iid)
    }

    private func references(_ requests: [PullRequestSummary]) -> String {
        requests.map { words.reference($0.iid) }.joined(separator: ", ")
    }

    private func remember(_ subscribed: Bool, _ ids: [Int]) {
        for id in ids {
            changes[id] = subscribed
        }
        if subscribed {
            unsubscribedIDs.subtract(ids)
        } else {
            unsubscribedIDs.formUnion(ids)
        }
        store.encode(unsubscribedIDs.sorted(), forKey: PullRequestsPreferenceKeys.unsubscribed(projectID: session.selectedProjectID))
    }

    private static func loadUnsubscribed(from store: any KeyValueStore, projectID: String) -> Set<Int> {
        Set(store.decode([Int].self, forKey: PullRequestsPreferenceKeys.unsubscribed(projectID: projectID)) ?? [])
    }
}
