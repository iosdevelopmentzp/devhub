import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct CommitRefTagMapperTests {
    @Test func everyRefKindHasItsTintAndIcon() {
        let tags = CommitRefTagMapper.tags(for: [
            GitCommitRef(kind: .head, name: "HEAD"),
            GitCommitRef(kind: .localBranch, name: "main"),
            GitCommitRef(kind: .remoteBranch, name: "origin/main"),
            GitCommitRef(kind: .tag, name: "v1.0"),
        ])

        #expect(tags.map(\.text) == ["HEAD", "main", "origin/main", "v1.0"])
        #expect(tags.map(\.tint) == [.blue, .indigo, .teal, .purple])
        #expect(tags.map(\.systemImage) == ["location.fill", "arrow.triangle.branch", "cloud", "tag"])
    }
}
