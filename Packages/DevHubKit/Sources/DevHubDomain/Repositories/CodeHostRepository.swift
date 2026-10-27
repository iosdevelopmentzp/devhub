import Foundation

package protocol CodeHostRepository: Sendable {
    func status(branch: String, repository: CodeHost) async throws -> PullRequestStatus
    func list(_ query: PullRequestQuery, after cursor: String?, repository: CodeHost) async throws -> PullRequestList
    func openRequests(repository: CodeHost) async throws -> PullRequestList
    func details(iid: Int, repository: CodeHost) async throws -> PullRequestDetails
    func diffs(iid: Int, repository: CodeHost) async throws -> [PullRequestFileDiff]
    func approve(iid: Int, repository: CodeHost) async throws
    func unapprove(iid: Int, repository: CodeHost) async throws
    func setDraft(iid: Int, isDraft: Bool, repository: CodeHost) async throws
    func rebase(iid: Int, repository: CodeHost) async throws
    func retryPipeline(id: Int, repository: CodeHost) async throws
    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws
    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws
    func cancelAutoMerge(iid: Int, repository: CodeHost) async throws
    func cancelPipeline(id: Int, repository: CodeHost) async throws
    func create(_ request: NewPullRequest, repository: CodeHost) async throws -> PullRequestSummary
    func labels(repository: CodeHost) async throws -> [String]
    func resolveThread(id: String, repository: CodeHost) async throws
    func reply(threadID: String, body: String, iid: Int, repository: CodeHost) async throws
    func comment(iid: Int, body: String, repository: CodeHost) async throws
    func requestChanges(iid: Int, body: String, repository: CodeHost) async throws
}
