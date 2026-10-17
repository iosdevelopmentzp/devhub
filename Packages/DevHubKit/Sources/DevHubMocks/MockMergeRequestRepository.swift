import Foundation
import DevHubDomain

struct MockMergeRequestRepository: MergeRequestRepository {

    func status(branch: String, repository: URL) async throws -> MergeRequestStatus {
        MergeRequestStatus(
            mergeRequest: MergeRequestInfo(
                iid: 1842,
                title: "ABC-2324: Paid call payment",
                state: .opened,
                isDraft: false,
                webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842"),
                author: "alex",
                hasConflicts: false,
                detailedStatus: .notApproved,
                targetBranch: "dev"
            ),
            pipeline: PipelineInfo(status: .success, webURL: nil, updatedAt: .now)
        )
    }

    func list(_ query: MergeRequestQuery, after cursor: String?, repository: URL) async throws -> MergeRequestList {
        try? await Task.sleep(for: .milliseconds(300))
        guard cursor == nil else { return MergeRequestList(username: MockData.gitLabUsername, requests: [], totalCount: 0) }
        let requests = MockData.mergeRequests.filter { request in
            switch query.scope {
            case .mine: if request.author != MockData.gitLabUsername { return false }
            case .reviewing: return ReviewQueuePolicy.needsMyReview(request, username: MockData.gitLabUsername)
            case .assigned: return false
            case .all: break
            }
            switch query.state {
            case .opened: return request.state == .opened
            case .merged: return request.state == .merged
            case .closed: return request.state == .closed
            case .all: return true
            }
        }
        return MergeRequestList(username: MockData.gitLabUsername, requests: requests, totalCount: requests.count)
    }

    func openRequests(repository: URL) async throws -> MergeRequestList {
        try await list(MergeRequestQuery(scope: .all, state: .opened), after: nil, repository: repository)
    }

    func details(iid: Int, repository: URL) async throws -> MergeRequestDetails {
        try? await Task.sleep(for: .milliseconds(300))
        return MockData.mergeRequestDetails
    }

    func diffs(iid: Int, repository: URL) async throws -> [MergeRequestFileDiff] {
        try? await Task.sleep(for: .milliseconds(300))
        return MockData.mergeRequestDiffs
    }

    func approve(iid: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func unapprove(iid: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func setDraft(iid: Int, isDraft: Bool, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func rebase(iid: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func retryPipeline(id: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func cancelAutoMerge(iid: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func cancelPipeline(id: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func create(_ request: NewMergeRequest, repository: URL) async throws -> MergeRequestSummary {
        try? await Task.sleep(for: .milliseconds(300))
        return MockData.mergeRequests[0]
    }

    func labels(repository: URL) async throws -> [String] {
        ["bugfix", "feature", "tech", "release"]
    }

    func resolveThread(id: String, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }

    func reply(threadID: String, body: String, iid: Int, repository: URL) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }
}
