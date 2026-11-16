import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class InboxStore {
    private(set) var items: [InboxItem] = []
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var busyIDs: Set<String> = []
    private(set) var pane: NotificationsPane = .events

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var loadedAt: Date?
    @ObservationIgnored private var loggedError: String?
    @ObservationIgnored private var pollingTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let staleAfter: TimeInterval = 60

    var words: CodeHostWords {
        remote.words
    }

    init(repository: CodeHostRepository, remote: any CodeHostLookup, activity: ActivityLog, notifier: Notifier, events: AppEvents) {
        self.repository = repository
        self.remote = remote
        self.activity = activity
        self.notifier = notifier
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                items = []
                loadedAt = nil
                error = nil
                Task { await self.refresh() }
            case .refreshRequested(.pullRequests):
                Task { await self.refresh() }
            default:
                break
            }
        }
    }

    var unreadCount: Int {
        items.count
    }

    func show(_ pane: NotificationsPane) {
        guard pane != self.pane else { return }
        self.pane = pane
    }

    func showInbox() {
        show(.inbox)
    }

    func startPolling() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await refresh()
                try? await Task.sleep(for: OpenPullRequestsStore.pollInterval(panelShown: notifier.isPanelShown, watching: false))
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
            isLoading = true
            defer { isLoading = false }
            do {
                let url = try await remote.codeHost()
                let loaded = try await repository.inbox(repository: url)
                try Task.checkCancellation()
                let fresh = loadedAt == nil ? [] : InboxChangePolicy.newItems(from: items, to: loaded)
                if loaded != items {
                    items = loaded
                }
                loadedAt = .now
                error = nil
                loggedError = nil
                report(fresh)
            } catch is CancellationError {
            } catch PullRequestError.noCodeHost {
            } catch {
                report(error)
            }
        }
    }

    func markDone(_ id: String) {
        guard busyIDs.contains(id) == false, let item = items.first(where: { $0.id == id }) else { return }
        busyIDs.insert(id)
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                try await repository.markInboxDone(id: id, repository: url)
                items.removeAll { $0.id == id }
            } catch {
                activity.log("Could not mark \(InboxItemText.reference(for: item, words: words)) as done", detail: error.localizedDescription, outcome: .failure)
            }
            busyIDs.remove(id)
        }
    }

    func markAllDone() {
        for item in items {
            markDone(item.id)
        }
    }

    private func report(_ fresh: [InboxItem]) {
        for item in fresh {
            let title = InboxItemText.title(for: item, words: words)
            let target = InboxItemText.target(for: item)
            activity.log(title, detail: item.excerpt ?? item.title, outcome: .info, kind: .inbox, target: target)
            notifier.notify(.inbox, title: title, body: item.excerpt ?? item.title, target: target)
        }
    }

    private func report(_ error: Error) {
        let message = error.localizedDescription
        self.error = message
        guard message != loggedError else { return }
        loggedError = message
        activity.log("Cannot read the Inbox of \(words.name)", detail: message, outcome: .failure)
    }
}
