import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class FlakyTestLedger {
    private(set) var records: [FlakyTestRecord] = []

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, events: AppEvents, store: any KeyValueStore) {
        self.session = session
        self.store = store
        records = Self.load(from: store, projectID: session.selectedProjectID)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            records = Self.load(from: store, projectID: session.selectedProjectID)
        }
    }

    var tests: [CIFlakyTest] {
        FlakyTrackingPolicy.tests(records)
    }

    func record(_ flakes: [CIFlakyTest], at date: Date) {
        guard flakes.isEmpty == false else { return }
        records = FlakyTrackingPolicy.add(flakes, to: records, at: date)
        store.encode(records, forKey: key)
    }

    func forget() {
        records = []
        store.remove(forKey: key)
    }

    private var key: String {
        PullRequestsPreferenceKeys.flakyTests(projectID: session.selectedProjectID)
    }

    private static func load(from store: any KeyValueStore, projectID: String) -> [FlakyTestRecord] {
        store.decode([FlakyTestRecord].self, forKey: PullRequestsPreferenceKeys.flakyTests(projectID: projectID)) ?? []
    }
}
