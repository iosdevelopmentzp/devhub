import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class PullRequestHiddenFiles {
    private(set) var paths: Set<String> = []

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, events: AppEvents, store: any KeyValueStore) {
        self.session = session
        self.store = store
        paths = Self.load(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            paths = Self.load(from: store, projectID: session.selectedProjectID)
        }
    }

    func hide(_ newPaths: [String]) {
        let updated = paths.union(newPaths)
        guard updated != paths else { return }
        paths = updated
        save()
    }

    func unhide(_ path: String) {
        guard paths.remove(path) != nil else { return }
        save()
    }

    private func save() {
        store.encode(paths.isEmpty ? nil : paths.sorted(), forKey: PullRequestsPreferenceKeys.hiddenFiles(projectID: session.selectedProjectID))
    }

    private static func load(from store: any KeyValueStore, projectID: String) -> Set<String> {
        Set(store.decode([String].self, forKey: PullRequestsPreferenceKeys.hiddenFiles(projectID: projectID)) ?? [])
    }
}
