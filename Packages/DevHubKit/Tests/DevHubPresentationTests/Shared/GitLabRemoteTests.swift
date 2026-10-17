import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct GitLabRemoteTests {
    private let harness = StoreHarness()
    private let remote = URL(string: "https://gitlab.example.com/team/app")!

    @Test func theURLIsReadOnceUntilTheProjectChanges() async throws {
        harness.spies.git.webURLResult = remote

        let first = try await harness.gitLabRemote.gitLabURL()
        let second = try await harness.gitLabRemote.gitLabURL()

        #expect(first == remote)
        #expect(second == remote)
        #expect(harness.spies.git.calls.count { $0 == .webURL(checkoutPath: ProjectSample.path) } == 1)

        harness.events.post(.projectChanged)
        _ = try await harness.gitLabRemote.gitLabURL()
        #expect(harness.spies.git.calls.count { $0 == .webURL(checkoutPath: ProjectSample.path) } == 2)
    }

    @Test func aMissingRemoteIsNotCached() async {
        await #expect(throws: MergeRequestError.notGitLab) {
            try await harness.gitLabRemote.gitLabURL()
        }

        harness.spies.git.webURLResult = remote
        let url = try? await harness.gitLabRemote.gitLabURL()
        #expect(url == remote)
    }
}
