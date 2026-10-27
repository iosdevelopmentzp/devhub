import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct BranchMarkDraftTests {
    @Test func startsFromTheMark() {
        let draft = BranchMarkDraft(mark: BranchMark(isPinned: true, labels: ["demo"], note: "Ask sam"))

        #expect(draft.labels == ["demo"])
        #expect(draft.note == "Ask sam")
        #expect(draft.newLabel.isEmpty)
    }

    @Test func toggleAddsAndRemovesALabel() {
        var draft = BranchMarkDraft(mark: BranchMark(labels: ["demo"]))

        draft.toggle("review")
        #expect(draft.labels == ["demo", "review"])
        #expect(draft.isSelected("review"))

        draft.toggle("demo")
        #expect(draft.labels == ["review"])
        #expect(draft.isSelected("demo") == false)
    }

    @Test func addNewLabelSplitsTheTextAndClearsTheField() {
        var draft = BranchMarkDraft(mark: BranchMark(labels: ["demo"]))
        draft.newLabel = "Demo, wip , after release"

        draft.addNewLabel()

        #expect(draft.labels == ["demo", "wip", "after release"])
        #expect(draft.newLabel.isEmpty)
    }

    @Test func finalLabelsIncludeTheTypedLabel() {
        var draft = BranchMarkDraft(mark: BranchMark(labels: ["demo"]))
        draft.newLabel = "review"

        #expect(draft.finalLabels == ["demo", "review"])
    }

    @Test func optionsAreKnownLabelsPlusSelectedOnes() {
        var draft = BranchMarkDraft(mark: BranchMark(labels: ["Demo", "new"]))
        draft.newLabel = "typed"

        #expect(draft.options(known: ["demo", "wip"]) == ["demo", "wip", "new"])
    }
}
