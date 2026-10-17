import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestFilterChipMapperTests {
    @Test func noFilterNoChips() {
        #expect(MergeRequestFilterChipMapper.chips(for: MergeRequestFilter()).isEmpty)
    }

    @Test func everyActiveFilterGetsAChipInMenuOrder() {
        let filter = MergeRequestFilter(targetBranch: "dev", label: "tech", onlyConflicts: true, onlyReady: true)

        #expect(MergeRequestFilterChipMapper.chips(for: filter) == [
            MergeRequestFilterChipModel(kind: .targetBranch, title: "into dev", systemImage: "arrow.triangle.branch"),
            MergeRequestFilterChipModel(kind: .label, title: "tech", systemImage: "tag"),
            MergeRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle"),
            MergeRequestFilterChipModel(kind: .onlyReady, title: "ready to merge", systemImage: "checkmark.circle"),
        ])
    }
}
