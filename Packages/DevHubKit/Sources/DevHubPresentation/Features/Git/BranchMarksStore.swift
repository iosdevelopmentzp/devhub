import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class BranchMarksStore {
    private(set) var marks: [String: BranchMark] = [:]

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, events: AppEvents, store: any KeyValueStore) {
        self.session = session
        self.store = store
        marks = load()
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            marks = load()
        }
    }

    var pinnedNames: Set<String> {
        Set(marks.filter(\.value.isPinned).keys)
    }

    var knownLabels: [String] {
        BranchLabelPolicy.known(in: marks.sorted { $0.key < $1.key }.map(\.value))
    }

    func mark(for branch: String) -> BranchMark {
        marks[branch] ?? BranchMark()
    }

    func togglePin(_ branch: String) {
        update(branch) { $0.isPinned.toggle() }
    }

    func setLabels(_ labels: [String], note: String, for branch: String) {
        update(branch) { mark in
            mark.labels = BranchLabelPolicy.merged([], adding: labels)
            mark.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func update(_ branch: String, _ change: (inout BranchMark) -> Void) {
        var mark = mark(for: branch)
        change(&mark)
        marks[branch] = mark.isEmpty ? nil : mark
        store.encode(marks.isEmpty ? nil : marks, forKey: key)
    }

    private func load() -> [String: BranchMark] {
        store.decode([String: BranchMark].self, forKey: key) ?? [:]
    }

    private var key: String {
        "git.branchMarks.\(session.selectedProjectID)"
    }
}
