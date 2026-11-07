import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class CIWorkflowHistory {
    private(set) var records: [Int: [CIWorkflowRecord]] = [:]

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let ledger: FlakyTestLedger
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, ledger: FlakyTestLedger, events: AppEvents, store: any KeyValueStore) {
        self.session = session
        self.ledger = ledger
        self.store = store
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            records = [:]
        }
    }

    var flakyTests: [CIFlakyTest] {
        ledger.tests
    }

    func records(for iid: Int) -> [CIWorkflowRecord] {
        records[iid] ?? []
    }

    func load(_ iid: Int) {
        guard records[iid] == nil else { return }
        records[iid] = store.decode([CIWorkflowRecord].self, forKey: key(iid)) ?? []
    }

    func remember(_ workflow: CIWorkflow, failedTests: [String: [CITestResult]], for iid: Int) {
        guard CIHistoryPolicy.isRecordable(workflow.status) else { return }
        load(iid)
        let record = CIHistoryPolicy.record(workflow, failedTests: failedTests, at: .now)
        let current = records(for: iid)
        let kept = CIHistoryPolicy.remember(record, in: current)
        guard kept != current else { return }
        if current.contains(where: { $0.id == record.id }) == false {
            ledger.record(FlakyTrackingPolicy.flakes(new: record, earlier: current), at: record.recordedAt)
        }
        records[iid] = kept
        store.encode(kept, forKey: key(iid))
    }

    func clear(_ iid: Int) {
        records[iid] = []
        store.remove(forKey: key(iid))
    }

    private func key(_ iid: Int) -> String {
        PullRequestsPreferenceKeys.ciHistory(projectID: session.selectedProjectID, iid: iid)
    }
}
