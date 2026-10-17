import Foundation
import DevHubDomain
import DevHubUI

enum BranchPullRequestMapper {

    static func model(for request: PullRequestSummary?) -> BranchPullRequestModel? {
        guard let request else { return nil }
        return BranchPullRequestModel(
            iid: request.iid,
            tag: TagModel(
                request.isDraft ? "!\(request.iid) draft" : "!\(request.iid)",
                tint: request.isDraft ? .gray : .blue,
                systemImage: "arrow.triangle.pull",
                hint: "Open merge request into \(request.targetBranch): \(request.title). Click to show it in the GitLab tab."
            ),
            pipelineTag: request.pipeline.map(PullRequestTagMapper.compactPipelineTag),
            pipelineURL: request.pipeline?.webURL,
            statusTags: statusTags(request),
            webURL: request.webURL,
            linkText: RequestLinkText.pullRequest(request)
        )
    }

    private static func statusTags(_ request: PullRequestSummary) -> [TagModel] {
        var tags: [TagModel] = []
        if request.approvedBy.isEmpty == false {
            tags.append(TagModel("approved", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by \(request.approvedBy.joined(separator: ", "))"))
        }
        if let threads = PullRequestTagMapper.openThreadsTag(open: request.openThreadCount, total: request.threadCount, comments: request.commentCount) {
            tags.append(threads)
        }
        return tags
    }
}
