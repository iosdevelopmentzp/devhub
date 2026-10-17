import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration), .enabled(if: Playground.path != nil, "Set DEVHUB_PLAYGROUND=owner/repo to read a GitHub test repository"))
struct GhIntegrationTests {
    private let repository: GhPullRequestRepository
    private let host: CodeHost

    init() throws {
        let path = try #require(Playground.path)
        repository = GhPullRequestRepository(client: GhClient(shell: ShellRunner(recorder: SpyCommandRecorder())))
        host = CodeHost(kind: .github, host: "github.com", path: path, webURL: try #require(URL(string: "https://github.com/\(path)")))
    }

    @Test func openRequestsBelongToTheRepository() async throws {
        let list = try await repository.list(PullRequestQuery(scope: .all, state: .opened), after: nil, repository: host)

        #expect(list.username.isEmpty == false)
        #expect(list.requests.isEmpty == false)
        #expect(list.requests.allSatisfy { $0.webURL?.absoluteString.hasPrefix(host.webURL.absoluteString) == true })
        #expect(list.requests.allSatisfy { $0.state == .opened })
    }

    @Test func mergedRequestsHaveAMergeDate() async throws {
        let list = try await repository.list(PullRequestQuery(scope: .all, state: .merged), after: nil, repository: host)

        #expect(list.requests.allSatisfy { $0.state == .merged && $0.mergedAt != nil })
    }

    @Test func aRequestWithAnOpenThreadShowsItWithItsFile() async throws {
        let list = try await repository.openRequests(repository: host)
        let request = try #require(list.requests.first { $0.openThreadCount > 0 })

        let details = try await repository.details(iid: request.iid, repository: host)

        #expect(details.threads.count == request.openThreadCount)
        #expect(details.threads.allSatisfy { $0.body.isEmpty == false })
    }

    @Test func filesComeWithTheirDiff() async throws {
        let request = try #require(try await repository.openRequests(repository: host).requests.first)

        let files = try await repository.diffs(iid: request.iid, repository: host)

        #expect(files.isEmpty == false)
        #expect(files.contains { $0.diff.lines.contains { $0.hasPrefix("@@") } })
    }

    @Test func theBranchStatusFindsItsRequest() async throws {
        let request = try #require(try await repository.openRequests(repository: host).requests.first)

        let status = try await repository.status(branch: request.sourceBranch, repository: host)

        #expect(status.pullRequest?.iid == request.iid)
    }

    @Test func labelsCanBeRead() async throws {
        _ = try await repository.labels(repository: host)
    }
}

private enum Playground {
    static let path = ProcessInfo.processInfo.environment["DEVHUB_PLAYGROUND"]
}
