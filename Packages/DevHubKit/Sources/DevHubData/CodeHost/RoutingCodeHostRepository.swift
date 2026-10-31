import Foundation
import DevHubDomain

struct RoutingCodeHostRepository: CodeHostRepository {
    let gitHub: any CodeHostRepository
    let gitLab: any CodeHostRepository

    func status(branch: String, repository: CodeHost) async throws -> PullRequestStatus {
        try await target(repository).status(branch: branch, repository: repository)
    }

    func list(_ query: PullRequestQuery, after cursor: String?, repository: CodeHost) async throws -> PullRequestList {
        try await target(repository).list(query, after: cursor, repository: repository)
    }

    func openRequests(repository: CodeHost) async throws -> PullRequestList {
        try await target(repository).openRequests(repository: repository)
    }

    func details(iid: Int, repository: CodeHost) async throws -> PullRequestDetails {
        try await target(repository).details(iid: iid, repository: repository)
    }

    func diffs(iid: Int, repository: CodeHost) async throws -> [PullRequestFileDiff] {
        try await target(repository).diffs(iid: iid, repository: repository)
    }

    func approve(iid: Int, repository: CodeHost) async throws {
        try await target(repository).approve(iid: iid, repository: repository)
    }

    func unapprove(iid: Int, repository: CodeHost) async throws {
        try await target(repository).unapprove(iid: iid, repository: repository)
    }

    func setDraft(iid: Int, isDraft: Bool, repository: CodeHost) async throws {
        try await target(repository).setDraft(iid: iid, isDraft: isDraft, repository: repository)
    }

    func rebase(iid: Int, repository: CodeHost) async throws {
        try await target(repository).rebase(iid: iid, repository: repository)
    }

    func retryPipeline(id: Int, repository: CodeHost) async throws {
        try await target(repository).retryPipeline(id: id, repository: repository)
    }

    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
        try await target(repository).merge(iid: iid, squash: squash, removeSourceBranch: removeSourceBranch, repository: repository)
    }

    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
        try await target(repository).setAutoMerge(iid: iid, sha: sha, squash: squash, removeSourceBranch: removeSourceBranch, repository: repository)
    }

    func cancelAutoMerge(iid: Int, repository: CodeHost) async throws {
        try await target(repository).cancelAutoMerge(iid: iid, repository: repository)
    }

    func cancelPipeline(id: Int, repository: CodeHost) async throws {
        try await target(repository).cancelPipeline(id: id, repository: repository)
    }

    func create(_ request: NewPullRequest, repository: CodeHost) async throws -> PullRequestSummary {
        try await target(repository).create(request, repository: repository)
    }

    func labels(repository: CodeHost) async throws -> [String] {
        try await target(repository).labels(repository: repository)
    }

    func resolveThread(id: String, repository: CodeHost) async throws {
        try await target(repository).resolveThread(id: id, repository: repository)
    }

    func reply(threadID: String, body: String, iid: Int, repository: CodeHost) async throws {
        try await target(repository).reply(threadID: threadID, body: body, iid: iid, repository: repository)
    }

    func comment(iid: Int, body: String, repository: CodeHost) async throws {
        try await target(repository).comment(iid: iid, body: body, repository: repository)
    }

    func requestChanges(iid: Int, body: String, repository: CodeHost) async throws {
        try await target(repository).requestChanges(iid: iid, body: body, repository: repository)
    }

    func addLineComment(iid: Int, comment: PullRequestLineComment, repository: CodeHost) async throws {
        try await target(repository).addLineComment(iid: iid, comment: comment, repository: repository)
    }

    func jobLog(jobID: String, repository: CodeHost) async throws -> String {
        try await target(repository).jobLog(jobID: jobID, repository: repository)
    }

    func retryJob(jobID: String, repository: CodeHost) async throws {
        try await target(repository).retryJob(jobID: jobID, repository: repository)
    }

    func fileContent(path: String, ref: String, repository: CodeHost) async throws -> String {
        try await target(repository).fileContent(path: path, ref: ref, repository: repository)
    }

    func inbox(repository: CodeHost) async throws -> [InboxItem] {
        try await target(repository).inbox(repository: repository)
    }

    func markInboxDone(id: String, repository: CodeHost) async throws {
        try await target(repository).markInboxDone(id: id, repository: repository)
    }

    private func target(_ repository: CodeHost) -> any CodeHostRepository {
        switch repository.kind {
        case .github: gitHub
        case .gitlab: gitLab
        }
    }
}
