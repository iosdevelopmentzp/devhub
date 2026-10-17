import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestActionMapper {

    static func primary(for request: PullRequestSummary, username: String?, words: CodeHostWords) -> [PullRequestActionModel] {
        guard request.state == .opened else { return [] }
        var actions: [PullRequestActionModel] = []
        if isPrimaryApproval(request, username: username) {
            actions.append(approve(words))
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
        if request.detailedStatus == .ciStillRunning, request.permissions.canSetAutoMerge, request.isAutoMergeEnabled == false {
            actions.append(PullRequestActionModel(
                id: .mergeWhenPipelinePasses,
                title: words.mergeWhenChecksPassTitle,
                systemImage: "clock.badge.checkmark",
                hint: "\(words.hostTitle) merges into \(request.targetBranch) once \(words.checksPass). Asks for squash and branch removal first.",
                tint: .purple
            ))
        }
        return actions
    }

    static func overflow(for request: PullRequestSummary, username: String?, words: CodeHostWords) -> [PullRequestActionModel] {
        guard request.state == .opened else { return [] }
        var actions: [PullRequestActionModel] = []
        if let username, request.author != username {
            if request.approvedBy.contains(username) {
                if request.permissions.canRevokeApproval {
                    actions.append(PullRequestActionModel(id: .unapprove, title: "Revoke Approval", systemImage: "xmark.seal", hint: "Remove your approval"))
                }
            } else if request.permissions.canApprove, isPrimaryApproval(request, username: username) == false {
                actions.append(approve(words))
            }
        }
        if request.isDraft {
            actions.append(PullRequestActionModel(id: .markReady, title: "Mark as Ready", systemImage: "checkmark.circle", hint: "Remove the Draft mark so it can be reviewed and merged"))
        } else {
            actions.append(PullRequestActionModel(id: .markDraft, title: "Mark as Draft", systemImage: "pencil.circle", hint: "Add the Draft mark: \(words.hostTitle) refuses to merge a draft"))
        }
        actions.append(PullRequestActionModel(id: .rebase, title: words.updateBranchTitle(target: request.targetBranch), systemImage: "arrow.triangle.branch", hint: words.updateBranchHint(target: request.targetBranch)))
        if request.pipeline?.status == .failed, request.pipeline?.id != nil {
            actions.append(PullRequestActionModel(id: .retryPipeline, title: words.retryChecksTitle, systemImage: "arrow.clockwise.circle", hint: "Run the failed \(words.job)s of the last commit again"))
        }
        if let pipeline = request.pipeline, pipeline.id != nil, PipelineStatePolicy.isActive(pipeline.status) {
            actions.append(PullRequestActionModel(id: .cancelPipeline, title: words.cancelChecksTitle, systemImage: "stop.circle", hint: "Stop the running \(words.checks) of the last commit"))
        }
        if request.isAutoMergeEnabled {
            actions.append(PullRequestActionModel(id: .cancelAutoMerge, title: "Cancel Auto-Merge", systemImage: "clock.badge.xmark", hint: "\(words.hostTitle) no longer merges this request when \(words.checksPass)"))
        }
        return actions
    }

    private static func approve(_ words: CodeHostWords) -> PullRequestActionModel {
        PullRequestActionModel(id: .approve, title: "Approve", systemImage: "checkmark.seal", hint: "Approve this \(words.request) as you", tint: .green)
    }

    private static func isPrimaryApproval(_ request: PullRequestSummary, username: String?) -> Bool {
        guard let username, request.permissions.canApprove else { return false }
        return ReviewQueuePolicy.needsMyReview(request, username: username)
    }
}
