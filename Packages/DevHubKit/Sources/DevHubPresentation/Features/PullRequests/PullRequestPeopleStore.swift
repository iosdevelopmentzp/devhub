import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class PullRequestPeopleStore {
    private(set) var people: [String] = []
    private(set) var teams: [String] = []
    private(set) var busyIDs: Set<PullRequestSummary.ID> = []

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: CodeHostRepository, remote: any CodeHostLookup, activity: ActivityLog, operations: OperationLog, events: AppEvents) {
        self.repository = repository
        self.remote = remote
        self.activity = activity
        self.operations = operations
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                people = []
                teams = []
                hasLoaded = false
            default:
                break
            }
        }
    }

    func loadIfNeeded() async {
        guard hasLoaded == false else { return }
        hasLoaded = true
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let host = try await remote.codeHost()
                let loaded = try await repository.people(repository: host)
                try Task.checkCancellation()
                people = loaded
                await loadTeams(host)
            } catch is CancellationError {
                hasLoaded = false
            } catch {
                hasLoaded = false
                activity.log("Cannot read the people of this project", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    private func loadTeams(_ host: CodeHost) async {
        do {
            let loaded = try await repository.teams(repository: host)
            try Task.checkCancellation()
            teams = loaded
        } catch is CancellationError {
        } catch {
            activity.log("Cannot read the teams of this project", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func toggle(_ login: String, role: PullRequestPersonRole, on summary: PullRequestSummary) {
        let id = summary.id
        guard busyIDs.contains(id) == false else { return }
        let isOn = (role == .reviewer ? summary.reviewers + summary.requestedTeams : summary.assignees).contains(login)
        let title = PullRequestPeopleText.title(login: login, role: role, adds: isOn == false, reference: remote.words.reference(id))
        busyIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(title, at: .pullRequest(id), retry: nil) {
                    try await repository.updatePeople(iid: id, role: role, add: isOn ? [] : [login], remove: isOn ? [login] : [], repository: remote.codeHost())
                }
                activity.log(title, detail: summary.title, outcome: .success)
                events.post(.refreshRequested(.pullRequests))
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
        }
    }
}
