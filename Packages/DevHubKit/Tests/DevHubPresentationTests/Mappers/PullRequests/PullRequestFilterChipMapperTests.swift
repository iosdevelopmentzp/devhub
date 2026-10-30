import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestFilterChipMapperTests {
    @Test func noFilterNoChips() {
        #expect(PullRequestFilterChipMapper.chips(for: PullRequestFilter()).isEmpty)
    }

    @Test func everyActiveFilterGetsAChipInMenuOrder() {
        let filter = PullRequestFilter(targetBranch: "dev", labels: ["tech", "bug"], author: "alex", assignee: "sam", reviewer: "kim", onlyConflicts: true, onlyReady: true)

        #expect(PullRequestFilterChipMapper.chips(for: filter) == [
            PullRequestFilterChipModel(kind: .targetBranch, title: "into dev", systemImage: "arrow.triangle.branch"),
            PullRequestFilterChipModel(kind: .label("tech"), title: "tech", systemImage: "tag"),
            PullRequestFilterChipModel(kind: .label("bug"), title: "bug", systemImage: "tag"),
            PullRequestFilterChipModel(kind: .author, title: "by alex", systemImage: "person.crop.circle"),
            PullRequestFilterChipModel(kind: .assignee, title: "assigned to sam", systemImage: "person.badge.shield.checkmark"),
            PullRequestFilterChipModel(kind: .reviewer, title: "review by kim", systemImage: "eyeglasses"),
            PullRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle"),
            PullRequestFilterChipModel(kind: .onlyReady, title: "ready to merge", systemImage: "checkmark.circle"),
        ])
    }
}
