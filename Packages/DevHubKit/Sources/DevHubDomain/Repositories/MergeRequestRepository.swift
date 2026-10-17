import Foundation

package protocol MergeRequestRepository: Sendable {
    func status(branch: String, repository: URL) async throws -> MergeRequestStatus
    func list(_ query: MergeRequestQuery, after cursor: String?, repository: URL) async throws -> MergeRequestList
    func openRequests(repository: URL) async throws -> MergeRequestList
    func details(iid: Int, repository: URL) async throws -> MergeRequestDetails
    func diffs(iid: Int, repository: URL) async throws -> [MergeRequestFileDiff]
    func approve(iid: Int, repository: URL) async throws
    func unapprove(iid: Int, repository: URL) async throws
    func setDraft(iid: Int, isDraft: Bool, repository: URL) async throws
    func rebase(iid: Int, repository: URL) async throws
    func retryPipeline(id: Int, repository: URL) async throws
    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws
    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws
    func cancelAutoMerge(iid: Int, repository: URL) async throws
    func cancelPipeline(id: Int, repository: URL) async throws
    func create(_ request: NewMergeRequest, repository: URL) async throws -> MergeRequestSummary
    func labels(repository: URL) async throws -> [String]
    func resolveThread(id: String, repository: URL) async throws
    func reply(threadID: String, body: String, iid: Int, repository: URL) async throws
}
