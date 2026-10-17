import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CodeHostRemoteTests {
    private let harness = StoreHarness()
    private let remote = CodeHost.gitLabSample

    @Test func theURLIsReadOnceUntilTheProjectChanges() async throws {
        harness.spies.git.webURLResult = remote.webURL

        let first = try await harness.codeHostRemote.codeHost()
        let second = try await harness.codeHostRemote.codeHost()

        #expect(first == remote)
        #expect(second == remote)
        #expect(harness.spies.git.calls.count { $0 == .webURL(checkoutPath: ProjectSample.path) } == 1)

        harness.events.post(.projectChanged)
        _ = try await harness.codeHostRemote.codeHost()
        #expect(harness.spies.git.calls.count { $0 == .webURL(checkoutPath: ProjectSample.path) } == 2)
    }

    @Test func aMissingRemoteIsNotCached() async {
        await #expect(throws: PullRequestError.noCodeHost) {
            try await harness.codeHostRemote.codeHost()
        }

        harness.spies.git.webURLResult = remote.webURL
        let url = try? await harness.codeHostRemote.codeHost()
        #expect(url == remote)
    }

    @Test func theConfiguredKindAndHostNameWin() async throws {
        harness.spies.git.webURLResult = remote.webURL
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(git: GitConfig(host: GitHostConfig(kind: .github, name: "code.example.com"))), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()

        let host = try await harness.codeHostRemote.codeHost()

        #expect(host.kind == .github)
        #expect(host.host == "code.example.com")
        #expect(host.path == "team/app")
    }

    @Test func theKindIsKnownAfterTheFirstRead() async throws {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        #expect(harness.codeHostRemote.kind == nil)

        _ = try await harness.codeHostRemote.codeHost()

        #expect(harness.codeHostRemote.kind == .github)
        #expect(harness.codeHostRemote.words.requestsTitle == "Pull Requests")
    }
}
