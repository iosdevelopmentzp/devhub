import DevHubDomain
import Testing

@Suite struct BranchLabelPolicyTests {
    @Test func textSplitsByCommaTrimsAndDropsEmptyParts() {
        #expect(BranchLabelPolicy.labels(from: " review ,  wip  later,, ") == ["review", "wip later"])
    }

    @Test func mergeKeepsOrderAndDropsCaseInsensitiveDuplicates() {
        #expect(BranchLabelPolicy.merged(["Review", "wip"], adding: ["review", "demo", " "]) == ["Review", "wip", "demo"])
    }

    @Test func knownLabelsAreUniqueAndSorted() {
        let marks = [
            BranchMark(labels: ["wip", "Demo"]),
            BranchMark(isPinned: true),
            BranchMark(labels: ["demo", "after release"]),
        ]

        #expect(BranchLabelPolicy.known(in: marks) == ["after release", "Demo", "wip"])
    }
}
