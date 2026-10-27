import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct BranchLabelMapperTests {
    @Test func labelsBecomeTagsWithATagIcon() {
        let tags = BranchLabelMapper.tags(for: ["review", "demo"])

        #expect(tags.map(\.text) == ["review", "demo"])
        #expect(tags.allSatisfy { $0.systemImage == "tag" })
    }

    @Test func tintIsStableAndIgnoresCase() {
        #expect(BranchLabelMapper.tint(for: "Review") == BranchLabelMapper.tint(for: "review"))
        #expect(BranchLabelMapper.tint(for: "a") == .pink)
        #expect(BranchLabelMapper.tint(for: "b") == .blue)
    }

    @Test func tintIsNeverRedOrGray() {
        let tints = Set(["a", "b", "c", "d", "e", "f", "g", "review", "wip"].map(BranchLabelMapper.tint(for:)))

        #expect(tints.isDisjoint(with: [.red, .gray, .secondary]))
    }
}
