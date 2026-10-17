import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestFilterChipMapperTests {
    @Test func noFilterNoChips() {
        #expect(PullRequestFilterChipMapper.chips(for: PullRequestFilter()).isEmpty)
    }

    @Test func everyActiveFilterGetsAChipInMenuOrder() {
        let filter = PullRequestFilter(targetBranch: "dev", label: "tech", onlyConflicts: true, onlyReady: true)

        #expect(PullRequestFilterChipMapper.chips(for: filter) == [
            PullRequestFilterChipModel(kind: .targetBranch, title: "into dev", systemImage: "arrow.triangle.branch"),
            PullRequestFilterChipModel(kind: .label, title: "tech", systemImage: "tag"),
            PullRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle"),
            PullRequestFilterChipModel(kind: .onlyReady, title: "ready to merge", systemImage: "checkmark.circle"),
        ])
    }
}
