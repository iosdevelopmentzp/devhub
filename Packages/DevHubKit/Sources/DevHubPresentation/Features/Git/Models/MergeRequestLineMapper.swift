import Foundation
import DevHubDomain
import DevHubUI

enum MergeRequestLineMapper {

    static func model(status: MergeRequestStatus?, error: MergeRequestError?, isLoading: Bool, openRequest: MergeRequestSummary?, username: String?) -> MergeRequestLineModel {
        MergeRequestLineModel(
            content: content(status: status, error: error, openRequest: openRequest, username: username),
            isLoading: isLoading,
            canRefresh: error != .notGitLab
        )
    }

    private static func content(status: MergeRequestStatus?, error: MergeRequestError?, openRequest: MergeRequestSummary?, username: String?) -> MergeRequestLineModel.Content {
        if case .notLoggedIn(let host) = error {
            return .notConnected(loginCommand: "glab auth login --hostname \(host)")
        }
        if let error {
            return .failure(error.localizedDescription)
        }
        guard let status else { return .checking }
        return .status(statusModel(status, openRequest: openRequest, username: username))
    }

    private static func statusModel(_ status: MergeRequestStatus, openRequest: MergeRequestSummary?, username: String?) -> MergeRequestLineModel.Status {
        let request = status.mergeRequest
        let summary = openRequest.flatMap { $0.iid == request?.iid ? $0 : nil }
        return MergeRequestLineModel.Status(
            requestTag: request.map { requestTag($0) },
            requestIID: request?.iid,
            requestURL: request?.webURL,
            linkText: request.map { RequestLinkText.mergeRequest(iid: $0.iid, title: $0.title, url: $0.webURL) },
            requestTags: (request.map { requestTags($0) } ?? []) + (summary.map { summaryTags($0, username: username) } ?? []),
            placeholder: request == nil ? "No merge request yet" : nil,
            pipelineTag: status.pipeline.map { MergeRequestTagMapper.pipelineTag($0, subject: "Latest pipeline on this branch") },
            pipelineURL: status.pipeline?.webURL
        )
    }

    private static func requestTag(_ request: MergeRequestInfo) -> TagModel {
        TagModel(
            "!\(request.iid) \(stateTitle(request))",
            tint: stateTint(request),
            systemImage: "arrow.triangle.pull",
            hint: "\(request.title)\nby \(request.author) into \(request.targetBranch). Click to show it in the GitLab tab."
        )
    }

    private static func requestTags(_ request: MergeRequestInfo) -> [TagModel] {
        var tags: [TagModel] = []
        if request.hasConflicts {
            tags.append(MergeRequestTagMapper.conflictsTag(targetBranch: request.targetBranch))
        }
        if let detail = request.detailedStatus, request.state == .opened, let tag = MergeRequestTagMapper.detailTag(detail) {
            tags.append(tag)
        }
        return tags
    }

    private static func summaryTags(_ summary: MergeRequestSummary, username: String?) -> [TagModel] {
        [
            MergeRequestTagMapper.approvalTag(approvedBy: summary.approvedBy, username: username),
            MergeRequestTagMapper.openThreadsTag(open: summary.openThreadCount, total: summary.threadCount, comments: summary.commentCount),
        ]
        .compactMap { $0 }
    }

    private static func stateTitle(_ request: MergeRequestInfo) -> String {
        if request.isDraft, request.state == .opened { return "draft" }
        switch request.state {
        case .opened: return "open"
        default: return request.state.name
        }
    }

    private static func stateTint(_ request: MergeRequestInfo) -> Tint {
        switch request.state {
        case .merged: .purple
        case .closed: .secondary
        default: request.isDraft ? .gray : .blue
        }
    }
}
