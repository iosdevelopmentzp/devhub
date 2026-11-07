import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class CIWatchStore {
    private(set) var onHold: [Int: [CIJob]] = [:]

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let openRequests: any OpenRequestsLookup
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let pollInterval: Duration
    @ObservationIgnored private var isPolling = false
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var checking: Set<Int> = []
    @ObservationIgnored private var notified: Set<NotifiedJob> = []
    @ObservationIgnored private var loggedErrors: [Int: String] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let warmUpInterval: Duration = .seconds(3)

    init(
        repository: CodeHostRepository,
        ci: any CIRepository,
        projects: CIProjectResolver,
        remote: any CodeHostLookup,
        openRequests: any OpenRequestsLookup,
        session: ProjectSession,
        activity: ActivityLog,
        notifier: Notifier,
        events: AppEvents,
        store: any KeyValueStore,
        pollInterval: Duration
    ) {
        self.repository = repository
        self.ci = ci
        self.projects = projects
        self.remote = remote
        self.openRequests = openRequests
        self.session = session
        self.activity = activity
        self.notifier = notifier
        self.store = store
        self.pollInterval = pollInterval
        notified = Self.loadNotified(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                pollingTask?.cancel()
                pollingTask = nil
                onHold = [:]
                loggedErrors = [:]
                notified = Self.loadNotified(from: store, projectID: session.selectedProjectID)
                resumePolling()
            case .pullRequestsChanged:
                Task { await self.checkAll() }
            case .pullRequestChecksChanged(let iid):
                Task { await self.check(iid) }
            default:
                break
            }
        }
    }

    var words: CodeHostWords {
        remote.words
    }

    var onHoldJobNames: [Int: [String]] {
        onHold.mapValues { $0.map(\.name) }
    }

    func startPolling() {
        isPolling = true
        resumePolling()
    }

    func checkAll() async {
        guard openRequests.username != nil else { return }
        let watched = watchedRequests
        for iid in onHold.keys where watched.contains(iid) == false {
            onHold[iid] = nil
        }
        forget(allBut: Set(openRequests.requests.map(\.iid)))
        for iid in watched {
            await check(iid)
        }
    }

    func check(_ iid: Int) async {
        guard checking.contains(iid) == false, watchedRequests.contains(iid) else { return }
        checking.insert(iid)
        defer { checking.remove(iid) }
        do {
            let url = try await remote.codeHost()
            let details = try await repository.details(iid: iid, repository: url)
            guard projects.hasProvider(for: details.jobs) else { return }
            let project = projects.project(for: details.jobs)
            var workflows: [CIWorkflow] = []
            for workflowID in CIPolicy.workflowIDs(of: details.jobs) {
                workflows.append(try await ci.workflow(id: workflowID, project: project))
            }
            loggedErrors[iid] = nil
            apply(CIWatchPolicy.jobsOnHold(in: workflows), to: iid)
        } catch is CancellationError {
        } catch {
            report(error, of: iid)
        }
    }

    private var watchedRequests: [Int] {
        CIWatchPolicy.watchedRequests(in: openRequests.requests, username: openRequests.username)
    }

    private func apply(_ jobs: [CIJob], to iid: Int) {
        let current = jobs.isEmpty ? nil : jobs
        if onHold[iid] != current {
            onHold[iid] = current
        }
        let fresh = jobs.filter { notified.contains(NotifiedJob(iid: iid, jobID: $0.id)) == false }
        guard fresh.isEmpty == false else { return }
        for job in fresh {
            notified.insert(NotifiedJob(iid: iid, jobID: job.id))
            let title = "\(job.name) of \(words.reference(iid)) waits for your approval"
            let body = "Approve it from the \(words.checks) of the \(words.request) in DevHub"
            activity.log(title, detail: body, outcome: .info, kind: .requestApprovals, target: .pullRequest(iid: iid))
            notifier.notify(.requestApprovals, title: title, body: body, target: .pullRequest(iid: iid))
        }
        saveNotified()
    }

    private func forget(allBut openIDs: Set<Int>) {
        let kept = notified.filter { openIDs.contains($0.iid) }
        guard kept != notified else { return }
        notified = kept
        saveNotified()
    }

    private func report(_ error: Error, of iid: Int) {
        let message = error.localizedDescription
        guard loggedErrors[iid] != message else { return }
        loggedErrors[iid] = message
        activity.log("Cannot check the CircleCI approvals of \(words.reference(iid))", detail: message, outcome: .failure)
    }

    private func resumePolling() {
        guard isPolling, pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await checkAll()
                try? await Task.sleep(for: openRequests.username == nil ? min(pollInterval, Self.warmUpInterval) : pollInterval)
            }
        }
    }

    private func saveNotified() {
        let kept = notified.sorted { ($0.iid, $0.jobID) < ($1.iid, $1.jobID) }
        store.encode(kept.isEmpty ? nil : kept, forKey: PullRequestsPreferenceKeys.ciNotified(projectID: session.selectedProjectID))
    }

    private static func loadNotified(from store: any KeyValueStore, projectID: String) -> Set<NotifiedJob> {
        Set(store.decode([NotifiedJob].self, forKey: PullRequestsPreferenceKeys.ciNotified(projectID: projectID)) ?? [])
    }
}

private struct NotifiedJob: Hashable, Codable {
    let iid: Int
    let jobID: String
}
