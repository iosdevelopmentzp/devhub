import Testing
@testable import DevHubDomain

@Suite struct UpdateCheckPolicyTests {
    private let commits = [UpdateCommit(hash: "a1b2c3d", subject: "feat: one"), UpdateCommit(hash: "d4e5f6a", subject: "fix: two")]

    @Test func behindTheRemoteIsAvailable() {
        #expect(UpdateCheckPolicy.result(installedIsOnRemote: true, newCommits: commits) == .available(commits))
    }

    @Test func equalToTheRemoteIsUpToDate() {
        #expect(UpdateCheckPolicy.result(installedIsOnRemote: true, newCommits: []) == .upToDate)
    }

    @Test func aheadOrUnknownInstalledCommitShowsNoUpdate() {
        #expect(UpdateCheckPolicy.result(installedIsOnRemote: false, newCommits: []) == .unknownInstalledCommit)
        #expect(UpdateCheckPolicy.result(installedIsOnRemote: false, newCommits: commits) == .unknownInstalledCommit)
    }
}
