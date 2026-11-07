import Foundation
import Testing
@testable import DevHubDomain

@Suite struct InstalledBuildTests {
    @Test func shortCommitAndRemoteBranch() {
        let build = InstalledBuild(commit: "0123456789abcdef0123456789abcdef01234567", branch: "main", source: "/Users/alex/source", installedAt: Date(timeIntervalSince1970: 1_800_000_000))

        #expect(build.shortCommit == "0123456")
        #expect(build.remoteBranch == "origin/main")
    }
}
