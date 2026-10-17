import DevHubDomain
import Foundation

package final class SpyMergeRequestRepository: MergeRequestRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case status(branch: String, repository: URL)
        case list(MergeRequestQuery, after: String?, repository: URL)
        case openRequests(repository: URL)
        case details(iid: Int, repository: URL)
        case diffs(iid: Int, repository: URL)
        case approve(iid: Int, repository: URL)
        case unapprove(iid: Int, repository: URL)
        case setDraft(iid: Int, isDraft: Bool, repository: URL)
        case rebase(iid: Int, repository: URL)
        case retryPipeline(id: Int, repository: URL)
        case merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: URL)
        case setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: URL)
        case cancelAutoMerge(iid: Int, repository: URL)
        case cancelPipeline(id: Int, repository: URL)
        case create(NewMergeRequest, repository: URL)
        case labels(repository: URL)
        case resolveThread(id: String, repository: URL)
        case reply(threadID: String, body: String, iid: Int, repository: URL)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _statusResult: Result<MergeRequestStatus, any Error> = .success(MergeRequestStatus(mergeRequest: nil, pipeline: nil))
    private var _listResult: Result<MergeRequestList, any Error> = .success(MergeRequestList(username: "me", requests: [], totalCount: 0))
    private var _nextPageResult: Result<MergeRequestList, any Error> = .success(MergeRequestList(username: "me", requests: [], totalCount: 0))
    private var _openRequestsResult: Result<MergeRequestList, any Error> = .success(MergeRequestList(username: "me", requests: [], totalCount: 0))
    private var _detailsResult: Result<MergeRequestDetails, any Error> = .success(MergeRequestDetails(description: "", threads: []))
    private var _diffsResult: Result<[MergeRequestFileDiff], any Error> = .success([])
    private var _actionError: (any Error)? = nil
    private var _createResult: Result<MergeRequestSummary, any Error>? = nil
    private var _labelsResult: Result<[String], any Error> = .success([])

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var statusResult: Result<MergeRequestStatus, any Error> {
        get { lock.withLock { _statusResult } }
        set { lock.withLock { _statusResult = newValue } }
    }

    package var nextPageResult: Result<MergeRequestList, any Error> {
        get { lock.withLock { _nextPageResult } }
        set { lock.withLock { _nextPageResult = newValue } }
    }

    package var listResult: Result<MergeRequestList, any Error> {
        get { lock.withLock { _listResult } }
        set { lock.withLock { _listResult = newValue } }
    }

    package var openRequestsResult: Result<MergeRequestList, any Error> {
        get { lock.withLock { _openRequestsResult } }
        set { lock.withLock { _openRequestsResult = newValue } }
    }

    package var detailsResult: Result<MergeRequestDetails, any Error> {
        get { lock.withLock { _detailsResult } }
        set { lock.withLock { _detailsResult = newValue } }
    }

    package var diffsResult: Result<[MergeRequestFileDiff], any Error> {
        get { lock.withLock { _diffsResult } }
        set { lock.withLock { _diffsResult = newValue } }
    }

    package var createResult: Result<MergeRequestSummary, any Error>? {
        get { lock.withLock { _createResult } }
        set { lock.withLock { _createResult = newValue } }
    }

    package var labelsResult: Result<[String], any Error> {
        get { lock.withLock { _labelsResult } }
        set { lock.withLock { _labelsResult = newValue } }
    }

    package func create(_ request: NewMergeRequest, repository: URL) async throws -> MergeRequestSummary {
        try record(.create(request, repository: repository)) {
            if let result = _createResult { return try result.get() }
            return MergeRequestSummary(
                iid: 1,
                title: request.title,
                state: .opened,
                isDraft: request.isDraft,
                webURL: nil,
                author: "me",
                sourceBranch: request.sourceBranch,
                targetBranch: request.targetBranch,
                hasConflicts: false,
                detailedStatus: nil,
                commentCount: 0,
                updatedAt: nil,
                pipeline: nil,
                approvedBy: [],
                labels: request.labels
            )
        }
    }

    package func labels(repository: URL) async throws -> [String] {
        try record(.labels(repository: repository)) { try _labelsResult.get() }
    }

    package var actionError: (any Error)? {
        get { lock.withLock { _actionError } }
        set { lock.withLock { _actionError = newValue } }
    }

    package func approve(iid: Int, repository: URL) async throws {
        try action(.approve(iid: iid, repository: repository))
    }

    package func unapprove(iid: Int, repository: URL) async throws {
        try action(.unapprove(iid: iid, repository: repository))
    }

    package func setDraft(iid: Int, isDraft: Bool, repository: URL) async throws {
        try action(.setDraft(iid: iid, isDraft: isDraft, repository: repository))
    }

    package func rebase(iid: Int, repository: URL) async throws {
        try action(.rebase(iid: iid, repository: repository))
    }

    package func retryPipeline(id: Int, repository: URL) async throws {
        try action(.retryPipeline(id: id, repository: repository))
    }

    package func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        try action(.merge(iid: iid, squash: squash, removeSourceBranch: removeSourceBranch, repository: repository))
    }

    package func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        try action(.setAutoMerge(iid: iid, sha: sha, squash: squash, removeSourceBranch: removeSourceBranch, repository: repository))
    }

    package func cancelAutoMerge(iid: Int, repository: URL) async throws {
        try action(.cancelAutoMerge(iid: iid, repository: repository))
    }

    package func cancelPipeline(id: Int, repository: URL) async throws {
        try action(.cancelPipeline(id: id, repository: repository))
    }

    package func resolveThread(id: String, repository: URL) async throws {
        try action(.resolveThread(id: id, repository: repository))
    }

    package func reply(threadID: String, body: String, iid: Int, repository: URL) async throws {
        try action(.reply(threadID: threadID, body: body, iid: iid, repository: repository))
    }

    private func action(_ call: Call) throws {
        try record(call) {
            if let error = _actionError { throw error }
        }
    }

    package func status(branch: String, repository: URL) async throws -> MergeRequestStatus {
        try record(.status(branch: branch, repository: repository)) { try _statusResult.get() }
    }

    package func list(_ query: MergeRequestQuery, after cursor: String?, repository: URL) async throws -> MergeRequestList {
        try record(.list(query, after: cursor, repository: repository)) { try (cursor == nil ? _listResult : _nextPageResult).get() }
    }

    package func openRequests(repository: URL) async throws -> MergeRequestList {
        try record(.openRequests(repository: repository)) { try _openRequestsResult.get() }
    }

    package func details(iid: Int, repository: URL) async throws -> MergeRequestDetails {
        try record(.details(iid: iid, repository: repository)) { try _detailsResult.get() }
    }

    package func diffs(iid: Int, repository: URL) async throws -> [MergeRequestFileDiff] {
        try record(.diffs(iid: iid, repository: repository)) { try _diffsResult.get() }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
