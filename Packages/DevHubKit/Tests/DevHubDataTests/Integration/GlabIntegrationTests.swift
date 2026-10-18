import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration), .serialized, .enabled(if: GitLabPlayground.value != nil, "Set DEVHUB_GITLAB_PLAYGROUND=<host>/<owner>/<repo> to write to a GitLab test project"))
struct GlabIntegrationTests {
    private let shell = ShellRunner(recorder: SpyCommandRecorder())
    private let repository: GlabPullRequestRepository
    private let host: CodeHost

    init() throws {
        let value = try #require(GitLabPlayground.value)
        let parts = value.split(separator: "/", maxSplits: 1).map(String.init)
        try #require(parts.count == 2)
        repository = GlabPullRequestRepository(client: GlabClient(shell: shell))
        host = CodeHost(kind: .gitlab, host: parts[0], path: parts[1], webURL: try #require(URL(string: "https://\(parts[0])/\(parts[1])")))
    }

    @Test func aMergeRequestGoesThroughDraftThreadAndMerge() async throws {
        let branch = "devhub-test-\(UUID().uuidString.prefix(8).lowercased())"
        try await makeBranch(branch)

        let created = try await repository.create(
            NewPullRequest(sourceBranch: branch, targetBranch: "main", title: "DevHub test \(branch)", description: "Created by GlabIntegrationTests.", labels: [], isDraft: true, removeSourceBranch: true, squash: true),
            repository: host
        )
        #expect(created.isDraft)

        try await repository.setDraft(iid: created.iid, isDraft: false, repository: host)
        #expect(try await request(created.iid, .opened)?.isDraft == false)
        try await repository.setDraft(iid: created.iid, isDraft: true, repository: host)
        #expect(try await request(created.iid, .opened)?.isDraft == true)
        try await repository.setDraft(iid: created.iid, isDraft: false, repository: host)

        try await startThread(iid: created.iid, body: "Thread from \(branch)")
        let thread = try #require(try await repository.details(iid: created.iid, repository: host).threads.first { $0.body == "Thread from \(branch)" })
        try await repository.reply(threadID: thread.id, body: "Reply from DevHub", iid: created.iid, repository: host)
        #expect(try await repository.details(iid: created.iid, repository: host).threads.first { $0.id == thread.id }?.replies.map(\.body) == ["Reply from DevHub"])

        try await repository.resolveThread(id: thread.id, repository: host)
        #expect(try await request(created.iid, .opened)?.resolvedThreadCount == 1)

        try await retrying { try await repository.merge(iid: created.iid, squash: true, removeSourceBranch: true, repository: host) }
        #expect(try await request(created.iid, .merged)?.mergedAt != nil)
    }

    @Test func labelsAndDiffsCanBeRead() async throws {
        _ = try await repository.labels(repository: host)
        let list = try await repository.list(PullRequestQuery(scope: .all, state: .merged), after: nil, repository: host)
        let merged = try #require(list.requests.first)

        #expect(try await repository.diffs(iid: merged.iid, repository: host).isEmpty == false)
    }

    private func request(_ iid: Int, _ state: PullRequestStateFilter) async throws -> PullRequestSummary? {
        try await repository.list(PullRequestQuery(scope: .all, state: state), after: nil, repository: host).requests.first { $0.iid == iid }
    }

    private func makeBranch(_ branch: String) async throws {
        try await api("projects/\(project)/repository/branches", ["-f", "branch=\(branch)", "-f", "ref=main"])
        try await api("projects/\(project)/repository/files/\(branch).txt", ["-f", "branch=\(branch)", "-f", "content=change on \(branch)", "-f", "commit_message=Add \(branch).txt"])
    }

    private func startThread(iid: Int, body: String) async throws {
        try await api("projects/\(project)/merge_requests/\(iid)/discussions", ["-f", "body=\(body)"])
    }

    private func api(_ endpoint: String, _ fields: [String]) async throws {
        let result = try await shell.run("glab", ["api", "--hostname", host.host, "-X", "POST", endpoint] + fields, cwd: nil)
        try #require(result.exitCode == 0, "\(endpoint): \(result.stderr)")
    }

    private var project: String {
        host.path.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? host.path
    }

    private func retrying(_ operation: () async throws -> Void) async throws {
        for attempt in 1...10 {
            do {
                return try await operation()
            } catch where attempt < 10 {
                try await ContinuousClock().sleep(for: .seconds(2))
            }
        }
    }
}

private enum GitLabPlayground {
    static let value = ProcessInfo.processInfo.environment["DEVHUB_GITLAB_PLAYGROUND"]
}
