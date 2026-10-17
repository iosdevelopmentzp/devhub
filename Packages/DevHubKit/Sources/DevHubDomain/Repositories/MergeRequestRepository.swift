import Foundation

package protocol MergeRequestRepository: Sendable {
    func status(branch: String, repository: CodeHost) async throws -> MergeRequestStatus
    func list(_ query: MergeRequestQuery, after cursor: String?, repository: CodeHost) async throws -> MergeRequestList
    func openRequests(repository: CodeHost) async throws -> MergeRequestList
    func details(iid: Int, repository: CodeHost) async throws -> MergeRequestDetails
    func diffs(iid: Int, repository: CodeHost) async throws -> [MergeRequestFileDiff]
    func approve(iid: Int, repository: CodeHost) async throws
    func unapprove(iid: Int, repository: CodeHost) async throws
    func setDraft(iid: Int, isDraft: Bool, repository: CodeHost) async throws
    func rebase(iid: Int, repository: CodeHost) async throws
    func retryPipeline(id: Int, repository: CodeHost) async throws
    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws
    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws
    func cancelAutoMerge(iid: Int, repository: CodeHost) async throws
    func cancelPipeline(id: Int, repository: CodeHost) async throws
    func create(_ request: NewMergeRequest, repository: CodeHost) async throws -> MergeRequestSummary
    func labels(repository: CodeHost) async throws -> [String]
    func resolveThread(id: String, repository: CodeHost) async throws
    func reply(threadID: String, body: String, iid: Int, repository: CodeHost) async throws
}
