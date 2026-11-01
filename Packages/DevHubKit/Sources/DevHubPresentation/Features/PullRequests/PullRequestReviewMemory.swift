import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class PullRequestReviewMemory {
    private(set) var snapshots: [String: ReviewSnapshot] = [:]

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, settings: SettingsStore, events: AppEvents, store: any KeyValueStore, now: @escaping () -> Date) {
        self.session = session
        self.settings = settings
        self.store = store
        self.now = now
        snapshots = Self.load(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            snapshots = Self.load(from: store, projectID: session.selectedProjectID)
        }
    }

    var isOn: Bool {
        settings.values.remembersReviews
    }

    func snapshot(of iid: Int) -> ReviewSnapshot? {
        isOn ? snapshots[String(iid)] : nil
    }

    func recordReview(of iid: Int, fingerprints: [String: String]) {
        guard isOn, fingerprints.isEmpty == false else { return }
        update(iid, ReviewChangePolicy.reviewed(snapshots[String(iid)], fingerprints: fingerprints, at: now()))
    }

    func setViewed(_ isViewed: Bool, path: String, fingerprint: String?, of iid: Int) {
        guard isOn else { return }
        update(iid, ReviewChangePolicy.settingViewed(isViewed, path: path, fingerprint: fingerprint, in: snapshots[String(iid)], at: now()))
    }

    func forget(_ iid: Int) {
        guard snapshots.removeValue(forKey: String(iid)) != nil else { return }
        save()
    }

    func forgetAll() {
        snapshots = [:]
        for project in session.projects {
            store.encode(nil as [String: ReviewSnapshot]?, forKey: PullRequestsPreferenceKeys.reviews(projectID: project.id))
        }
    }

    private func update(_ iid: Int, _ snapshot: ReviewSnapshot) {
        snapshots[String(iid)] = snapshot
        snapshots = ReviewChangePolicy.pruned(snapshots)
        save()
    }

    private func save() {
        store.encode(snapshots.isEmpty ? nil : snapshots, forKey: PullRequestsPreferenceKeys.reviews(projectID: session.selectedProjectID))
    }

    private static func load(from store: any KeyValueStore, projectID: String) -> [String: ReviewSnapshot] {
        store.decode([String: ReviewSnapshot].self, forKey: PullRequestsPreferenceKeys.reviews(projectID: projectID)) ?? [:]
    }
}
