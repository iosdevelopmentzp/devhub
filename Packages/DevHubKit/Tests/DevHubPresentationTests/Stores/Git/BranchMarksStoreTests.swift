import Foundation
import Testing
import DevHubDomain
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct BranchMarksStoreTests {
    private let harness = StoreHarness(projects: [ProjectSample.app, ProjectSample.other])

    private var store: BranchMarksStore {
        harness.branchMarks
    }

    @Test func togglePinPinsAndUnpins() {
        store.togglePin("feature/a")

        #expect(store.pinnedNames == ["feature/a"])
        #expect(store.mark(for: "feature/a").isPinned)

        store.togglePin("feature/a")

        #expect(store.pinnedNames.isEmpty)
        #expect(store.marks.isEmpty)
    }

    @Test func setLabelsCleansLabelsAndTrimsTheNote() {
        store.setLabels(["review", " Review ", "", "demo"], note: "  Ask sam \n", for: "feature/a")

        #expect(store.mark(for: "feature/a") == BranchMark(labels: ["review", "demo"], note: "Ask sam"))
    }

    @Test func clearingLabelsAndNoteKeepsThePin() {
        store.togglePin("feature/a")
        store.setLabels(["review"], note: "x", for: "feature/a")

        store.setLabels([], note: " ", for: "feature/a")

        #expect(store.mark(for: "feature/a") == BranchMark(isPinned: true))
    }

    @Test func knownLabelsComeFromEveryBranch() {
        store.setLabels(["wip", "demo"], note: "", for: "feature/a")
        store.setLabels(["Demo", "after release"], note: "", for: "feature/b")

        #expect(store.knownLabels == ["after release", "demo", "wip"])
    }

    @Test func marksPersistPerProject() {
        store.togglePin("feature/a")
        let key = "git.branchMarks.\(ProjectSample.app.id)"

        #expect(harness.store.decode([String: BranchMark].self, forKey: key) == ["feature/a": BranchMark(isPinned: true)])

        let reloaded = BranchMarksStore(session: harness.session, events: harness.events, store: harness.store)

        #expect(reloaded.pinnedNames == ["feature/a"])
    }

    @Test func switchingTheProjectLoadsItsOwnMarks() {
        store.togglePin("feature/a")

        harness.session.selectedProjectID = ProjectSample.other.id

        #expect(store.marks.isEmpty)

        store.togglePin("feature/b")
        harness.session.selectedProjectID = ProjectSample.app.id

        #expect(store.pinnedNames == ["feature/a"])
    }

    @Test func removingTheLastMarkRemovesTheKey() {
        store.togglePin("feature/a")
        store.togglePin("feature/a")

        #expect(harness.store.data(forKey: "git.branchMarks.\(ProjectSample.app.id)") == nil)
    }
}
