import DevHubDomain
import Testing

@Suite struct BranchMarkTests {
    @Test func markWithoutPinLabelsOrNoteIsEmpty() {
        #expect(BranchMark().isEmpty)
        #expect(BranchMark(isPinned: true).isEmpty == false)
        #expect(BranchMark(labels: ["a"]).isEmpty == false)
        #expect(BranchMark(note: "a").isEmpty == false)
    }
}
