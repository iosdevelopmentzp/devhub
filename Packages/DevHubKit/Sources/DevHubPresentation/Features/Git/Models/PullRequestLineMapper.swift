import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestLineMapper {

    static func model(status: PullRequestStatus?, error: PullRequestError?, isLoading: Bool, openRequest: PullRequestSummary?, username: String?, words: CodeHostWords) -> PullRequestLineModel {
        PullRequestLineModel(
            content: content(status: status, error: error, openRequest: openRequest, username: username, words: words),
            isLoading: isLoading,
            canRefresh: error != .noCodeHost
        )
    }

    private static func content(status: PullRequestStatus?, error: PullRequestError?, openRequest: PullRequestSummary?, username: String?, words: CodeHostWords) -> PullRequestLineModel.Content {
        if case .notLoggedIn(let tool, let host) = error {
            return .notConnected(loginCommand: "\(tool) auth login --hostname \(host)")
        }
        if let error {
            return .failure(error.localizedDescription)
        }
        guard let status else { return .checking }
        return .status(statusModel(status, openRequest: openRequest, username: username, words: words))
    }

    private static func statusModel(_ status: PullRequestStatus, openRequest: PullRequestSummary?, username: String?, words: CodeHostWords) -> PullRequestLineModel.Status {
        let request = status.pullRequest
        let summary = openRequest.flatMap { $0.iid == request?.iid ? $0 : nil }
        return PullRequestLineModel.Status(
            requestTag: request.map { requestTag($0, words: words) },
            requestIID: request?.iid,
            requestURL: request?.webURL,
            linkText: request.map { RequestLinkText.pullRequest(iid: $0.iid, title: $0.title, url: $0.webURL, words: words) },
            requestTags: (request.map { requestTags($0, words: words) } ?? []) + (summary.map { summaryTags($0, username: username) } ?? []),
            placeholder: request == nil ? "No \(words.request) yet" : nil,
            pipelineTag: status.pipeline.map { PullRequestTagMapper.pipelineTag($0, subject: "Latest \(words.checks) on this branch", words: words) },
            pipelineURL: status.pipeline?.webURL
        )
    }

    private static func requestTag(_ request: PullRequestInfo, words: CodeHostWords) -> TagModel {
        TagModel(
            "\(words.reference(request.iid)) \(stateTitle(request))",
            tint: stateTint(request),
            systemImage: "arrow.triangle.pull",
            hint: "\(request.title)\nby \(request.author) into \(request.targetBranch). Click to show it in the \(words.requestsTitle) tab."
        )
    }

    private static func requestTags(_ request: PullRequestInfo, words: CodeHostWords) -> [TagModel] {
        var tags: [TagModel] = []
        if request.hasConflicts {
            tags.append(PullRequestTagMapper.conflictsTag(targetBranch: request.targetBranch, words: words))
        }
        if let detail = request.detailedStatus, request.state == .opened, let tag = PullRequestTagMapper.detailTag(detail, words: words) {
            tags.append(tag)
        }
        return tags
    }

    private static func summaryTags(_ summary: PullRequestSummary, username: String?) -> [TagModel] {
        [
            PullRequestTagMapper.approvalTag(approvedBy: summary.approvedBy, username: username),
            PullRequestTagMapper.openThreadsTag(open: summary.openThreadCount, total: summary.threadCount, comments: summary.commentCount),
        ]
        .compactMap { $0 }
    }

    private static func stateTitle(_ request: PullRequestInfo) -> String {
        if request.isDraft, request.state == .opened { return "draft" }
        switch request.state {
        case .opened: return "open"
        default: return request.state.name
        }
    }

    private static func stateTint(_ request: PullRequestInfo) -> Tint {
        switch request.state {
        case .merged: .purple
        case .closed: .secondary
        default: request.isDraft ? .gray : .blue
        }
    }
}
