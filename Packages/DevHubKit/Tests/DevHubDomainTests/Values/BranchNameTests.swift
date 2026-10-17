import Testing
@testable import DevHubDomain

@Suite struct BranchNameTests {
    @Test func localDropsRemotePrefix() {
        #expect(BranchName("origin/dev", remote: "origin").local == "dev")
    }

    @Test func localKeepsALocalName() {
        #expect(BranchName("feature/login", remote: "origin").local == "feature/login")
    }

    @Test func localKeepsOtherRemotes() {
        #expect(BranchName("upstream/dev", remote: "origin").local == "upstream/dev")
    }

    @Test func remoteRefAddsTheOriginPrefix() {
        #expect(BranchName("feature/login", remote: "origin").remoteRef == "origin/feature/login")
    }

    @Test func remoteRefDoesNotDoubleThePrefix() {
        #expect(BranchName("origin/dev", remote: "origin").remoteRef == "origin/dev")
    }

    @Test func anotherRemoteUsesItsOwnPrefix() {
        #expect(BranchName("upstream/dev", remote: "upstream").local == "dev")
        #expect(BranchName("origin/dev", remote: "upstream").local == "origin/dev")
        #expect(BranchName("feature/login", remote: "upstream").remoteRef == "upstream/feature/login")
    }
}
