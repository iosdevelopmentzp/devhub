import Foundation
import DevHubDomain
import DevHubUI

enum MergeRequestRowMapper {

    static func model(for request: MergeRequestSummary, context: MergeRequestRowContext, local: MergeRequestLocalState, isBusy: Bool, isExpanded: Bool) -> MergeRequestRowModel {
        let username = context.username
        let isOpen = request.state == .opened
        return MergeRequestRowModel(
            id: request.id,
            reference: "!\(request.iid)",
            title: request.title,
            icon: icon(request),
            iconTint: tint(request),
            iconHint: stateTitle(request),
            isNew: MergeRequestAgePolicy.isNew(request, seenAt: context.seenAt),
            ticket: TicketMapper.model(for: [request.title, request.sourceBranch], template: context.ticketURLTemplate),
            linkText: RequestLinkText.mergeRequest(request),
            author: context.scope == .mine ? "" : request.author,
            authorTint: request.author == username ? .blue : nil,
            authorHint: request.author == username ? "Opened by you" : "Opened by \(request.author)",
            sourceBranch: request.sourceBranch,
            targetBranch: request.targetBranch,
            dateText: dateText(request),
            dateHint: request.createdAt.map { "opened \($0.relativeDescription)" },
            statsText: statsText(request),
            tags: (isOpen ? [MergeRequestLocalStateMapper.tag(for: local)].compactMap { $0 } : []) + tags(request, context: context),
            pipelineTag: request.pipeline.map(MergeRequestTagMapper.compactPipelineTag),
            pipelineURL: request.pipeline?.webURL,
            labelTags: request.labels.map { TagModel($0, tint: .secondary, systemImage: "tag", hint: "Label on GitLab") },
            usesPlainTags: false,
            webURL: request.webURL,
            canCheckOut: isOpen,
            canCreateWorktree: isOpen && (local == .local || local == .none),
            canSwitchBranch: isOpen && local == .local && context.isMainCheckoutClean,
            worktreePath: worktreePath(local),
            canFixThreads: isOpen && request.openThreadCount > 0,
            primaryActions: MergeRequestActionMapper.primary(for: request, username: username),
            actions: MergeRequestActionMapper.overflow(for: request, username: username),
            mergeTitle: "Merge !\(request.iid) into \(request.targetBranch)?",
            autoMergeTitle: "Merge !\(request.iid) into \(request.targetBranch) when the pipeline passes?",
            squashByDefault: request.squashOnMerge,
            removeSourceBranchByDefault: request.removesSourceBranch ?? true,
            isBusy: isBusy,
            isExpanded: isExpanded
        )
    }

    private static func tags(_ request: MergeRequestSummary, context: MergeRequestRowContext) -> [TagModel] {
        let isOpen = request.state == .opened
        var tags: [TagModel] = []
        if request.isDraft, isOpen {
            tags.append(TagModel("draft", tint: .gray, hint: "Draft: not ready for review"))
        }
        if isOpen == false {
            tags.append(TagModel(request.state.name, tint: tint(request)))
        }
        if context.scope != .reviewing, let username = context.username, ReviewQueuePolicy.needsMyReview(request, username: username) {
            tags.append(TagModel("needs your review", tint: .indigo, systemImage: "eye", hint: "Opened by \(request.author), not a draft, you have not approved it"))
        }
        if request.hasConflicts, isOpen {
            tags.append(MergeRequestTagMapper.conflictsTag(targetBranch: request.targetBranch))
        }
        if let detail = request.detailedStatus, isOpen, showsDetail(detail, of: request), let tag = MergeRequestTagMapper.detailTag(detail) {
            tags.append(tag)
        }
        if request.isAutoMergeEnabled, isOpen {
            tags.append(TagModel("auto-merge", tint: .blue, systemImage: "clock.badge.checkmark", hint: "GitLab merges it into \(request.targetBranch) when the pipeline passes"))
        }
        if request.isBehindTarget, isOpen {
            tags.append(MergeRequestTagMapper.behindTag(targetBranch: request.targetBranch))
        }
        if MergeRequestAgePolicy.isStale(request, now: context.now) {
            tags.append(TagModel("stale", tint: .orange, systemImage: "hourglass", hint: "No update for 14 days or more"))
        }
        if let approval = MergeRequestTagMapper.approvalTag(approvedBy: request.approvedBy, username: context.username) {
            tags.append(approval)
        }
        if isOpen, let threads = MergeRequestTagMapper.openThreadsTag(open: request.openThreadCount, total: request.threadCount, comments: request.commentCount) {
            tags.append(threads)
        }
        return tags
    }

    private static func worktreePath(_ local: MergeRequestLocalState) -> String? {
        guard case .worktree(let path) = local else { return nil }
        return path
    }

    private static func showsDetail(_ detail: MergeDetail, of request: MergeRequestSummary) -> Bool {
        detail != .discussionsNotResolved || request.openThreadCount == 0
    }

    private static func dateText(_ request: MergeRequestSummary) -> String? {
        switch request.state {
        case .merged:
            if let mergedAt = request.mergedAt {
                return "merged\(request.mergedBy.map { " by \($0)" } ?? "") \(mergedAt.relativeDescription)"
            }
        case .closed:
            if let closedAt = request.closedAt {
                return "closed \(closedAt.relativeDescription)"
            }
        default:
            break
        }
        return request.updatedAt.map { "updated \($0.relativeDescription)" }
    }

    private static func statsText(_ request: MergeRequestSummary) -> String? {
        var parts: [String] = []
        if let stats = request.diffStats {
            parts.append("+\(stats.additions) −\(stats.deletions)")
            parts.append(CountText.count(stats.fileCount, "file"))
        }
        if let commits = request.commitCount {
            parts.append(CountText.count(commits, "commit"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func icon(_ request: MergeRequestSummary) -> String {
        switch request.state {
        case .merged: "arrow.triangle.merge"
        case .closed: "xmark.circle"
        default: "arrow.triangle.pull"
        }
    }

    private static func tint(_ request: MergeRequestSummary) -> Tint {
        switch request.state {
        case .merged: .purple
        case .closed: .secondary
        default: request.isDraft ? .gray : .blue
        }
    }

    private static func stateTitle(_ request: MergeRequestSummary) -> String {
        if request.isDraft, request.state == .opened { return "Draft" }
        switch request.state {
        case .opened: return "Open"
        case .merged: return "Merged"
        case .closed: return "Closed"
        default: return request.state.name.capitalized
        }
    }
}
