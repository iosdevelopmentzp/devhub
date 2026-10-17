import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestActionMapper {

    static func primary(for request: PullRequestSummary, username: String?) -> [PullRequestActionModel] {
        guard request.state == .opened else { return [] }
        var actions: [PullRequestActionModel] = []
        if isPrimaryApproval(request, username: username) {
            actions.append(approve)
        }
        if request.detailedStatus == .mergeable, request.permissions.canMerge {
            actions.append(PullRequestActionModel(
                id: .merge,
                title: "Merge…",
                systemImage: "arrow.triangle.merge",
                hint: "Merge into \(request.targetBranch) after a confirmation with squash and branch removal options",
                tint: .purple
            ))
        }
        if request.detailedStatus == .ciStillRunning, request.permissions.canMerge, request.isAutoMergeEnabled == false {
            actions.append(PullRequestActionModel(
                id: .mergeWhenPipelinePasses,
                title: "Merge When Pipeline Passes…",
                systemImage: "clock.badge.checkmark",
                hint: "GitLab merges into \(request.targetBranch) once the pipeline passes. Asks for squash and branch removal first.",
                tint: .purple
            ))
        }
        return actions
    }

    static func overflow(for request: PullRequestSummary, username: String?) -> [PullRequestActionModel] {
        guard request.state == .opened else { return [] }
        var actions: [PullRequestActionModel] = []
        if let username, request.author != username {
            if request.approvedBy.contains(username) {
                actions.append(PullRequestActionModel(id: .unapprove, title: "Revoke Approval", systemImage: "xmark.seal", hint: "Remove your approval"))
            } else if request.permissions.canApprove, isPrimaryApproval(request, username: username) == false {
                actions.append(approve)
            }
        }
        if request.isDraft {
            actions.append(PullRequestActionModel(id: .markReady, title: "Mark as Ready", systemImage: "checkmark.circle", hint: "Remove the Draft mark so it can be reviewed and merged"))
        } else {
            actions.append(PullRequestActionModel(id: .markDraft, title: "Mark as Draft", systemImage: "pencil.circle", hint: "Add the Draft mark: GitLab refuses to merge a draft"))
        }
        actions.append(PullRequestActionModel(id: .rebase, title: "Rebase onto \(request.targetBranch)", systemImage: "arrow.triangle.branch", hint: "GitLab rebases the source branch onto \(request.targetBranch) on the server. Fails on conflicts."))
        if request.pipeline?.status == .failed, request.pipeline?.id != nil {
            actions.append(PullRequestActionModel(id: .retryPipeline, title: "Retry Pipeline", systemImage: "arrow.clockwise.circle", hint: "Run the failed jobs of the last pipeline again"))
        }
        if let pipeline = request.pipeline, pipeline.id != nil, PipelineStatePolicy.isActive(pipeline.status) {
            actions.append(PullRequestActionModel(id: .cancelPipeline, title: "Cancel Pipeline", systemImage: "stop.circle", hint: "Stop the running pipeline of the last commit"))
        }
        if request.isAutoMergeEnabled {
            actions.append(PullRequestActionModel(id: .cancelAutoMerge, title: "Cancel Auto-Merge", systemImage: "clock.badge.xmark", hint: "GitLab no longer merges this request when the pipeline passes"))
        }
        return actions
    }

    private static let approve = PullRequestActionModel(id: .approve, title: "Approve", systemImage: "checkmark.seal", hint: "Approve this merge request as you", tint: .green)

    private static func isPrimaryApproval(_ request: PullRequestSummary, username: String?) -> Bool {
        guard let username, request.permissions.canApprove else { return false }
        return ReviewQueuePolicy.needsMyReview(request, username: username)
    }
}
