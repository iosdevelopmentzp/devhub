import Testing
@testable import DevHubDomain

@Suite struct BranchNameTests {
    @Test func localDropsRemotePrefix() {
        #expect(BranchName("origin/dev").local == "dev")
    }

    @Test func localKeepsALocalName() {
        #expect(BranchName("feature/login").local == "feature/login")
    }

    @Test func localKeepsOtherRemotes() {
        #expect(BranchName("upstream/dev").local == "upstream/dev")
    }

    @Test func remoteRefAddsTheOriginPrefix() {
        #expect(BranchName("feature/login").remoteRef == "origin/feature/login")
    }

    @Test func remoteRefDoesNotDoubleThePrefix() {
        #expect(BranchName("origin/dev").remoteRef == "origin/dev")
    }

    @Test func defaultBaseRefIsOriginMain() {
        #expect(BranchName.defaultBaseRef == "origin/main")
    }
}
