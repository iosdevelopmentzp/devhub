import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestRowMapper {

    static func model(for request: PullRequestSummary, context: PullRequestRowContext, local: PullRequestLocalState, isBusy: Bool, isExpanded: Bool, configActions: [ConfigActionItemModel]) -> PullRequestRowModel {
        let username = context.username
        let words = context.words
        let isOpen = request.state == .opened
        return PullRequestRowModel(
            id: request.id,
            reference: words.reference(request.iid),
            title: request.title,
            icon: icon(request),
            iconTint: tint(request),
            iconHint: stateTitle(request),
            isNew: PullRequestAgePolicy.isNew(request, seenAt: context.seenAt),
            ticket: TicketMapper.model(for: [request.title, request.sourceBranch], ticket: context.ticket),
            linkText: RequestLinkText.pullRequest(request, words: words),
            author: context.scope == .mine ? "" : request.author,
            authorTint: request.author == username ? .blue : nil,
            authorHint: request.author == username ? "Opened by you" : "Opened by \(request.author)",
            sourceBranch: request.sourceBranch,
            targetBranch: request.targetBranch,
            dateText: dateText(request),
            dateHint: request.createdAt.map { "opened \($0.relativeDescription)" },
            statsText: statsText(request),
            tags: (isOpen ? [PullRequestLocalStateMapper.tag(for: local)].compactMap { $0 } : []) + tags(request, context: context),
            pipelineTag: request.pipeline.map { PullRequestTagMapper.compactPipelineTag($0, words: words) },
            pipelineURL: request.pipeline?.webURL,
            labelTags: request.labels.map { TagModel($0, tint: .secondary, systemImage: "tag", hint: "Label on \(words.name)") },
            usesPlainTags: false,
            webURL: request.webURL,
            canCheckOut: isOpen,
            canCreateWorktree: isOpen && (local == .local || local == .none),
            canSwitchBranch: isOpen && local == .local && context.isMainCheckoutClean,
            worktreePath: worktreePath(local),
            canFixThreads: isOpen && request.openThreadCount > 0,
            primaryActions: PullRequestActionMapper.primary(for: request, username: username, words: words),
            actions: PullRequestActionMapper.overflow(for: request, username: username, words: words),
            mergeTitle: "Merge \(words.reference(request.iid)) into \(request.targetBranch)?",
            autoMergeTitle: "Merge \(words.reference(request.iid)) into \(request.targetBranch) when \(words.checksPass)?",
            squashByDefault: request.squashOnMerge,
            removeSourceBranchByDefault: request.removesSourceBranch ?? true,
            isBusy: isBusy,
            isExpanded: isExpanded,
            configActions: request.state == .opened ? configActions : []
        )
    }

    private static func tags(_ request: PullRequestSummary, context: PullRequestRowContext) -> [TagModel] {
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
            tags.append(PullRequestTagMapper.conflictsTag(targetBranch: request.targetBranch, words: context.words))
        }
        if let detail = request.detailedStatus, isOpen, showsDetail(detail, of: request), let tag = PullRequestTagMapper.detailTag(detail, words: context.words) {
            tags.append(tag)
        }
        if request.isAutoMergeEnabled, isOpen {
            tags.append(TagModel("auto-merge", tint: .blue, systemImage: "clock.badge.checkmark", hint: "\(context.words.hostTitle) merges it into \(request.targetBranch) when \(context.words.checksPass)"))
        }
        if request.isBehindTarget, isOpen {
            tags.append(PullRequestTagMapper.behindTag(targetBranch: request.targetBranch, words: context.words))
        }
        if PullRequestAgePolicy.isStale(request, now: context.now, staleDays: context.staleDays) {
            tags.append(TagModel("stale", tint: .orange, systemImage: "hourglass", hint: "No update for \(context.staleDays) days or more"))
        }
        if let approval = PullRequestTagMapper.approvalTag(approvedBy: request.approvedBy, username: context.username) {
            tags.append(approval)
        }
        if isOpen, let threads = PullRequestTagMapper.openThreadsTag(open: request.openThreadCount, total: request.threadCount, comments: request.commentCount) {
            tags.append(threads)
        }
        return tags
    }

    private static func worktreePath(_ local: PullRequestLocalState) -> String? {
        guard case .worktree(let path) = local else { return nil }
        return path
    }

    private static func showsDetail(_ detail: MergeDetail, of request: PullRequestSummary) -> Bool {
        detail != .discussionsNotResolved || request.openThreadCount == 0
    }

    private static func dateText(_ request: PullRequestSummary) -> String? {
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

    private static func statsText(_ request: PullRequestSummary) -> String? {
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

    private static func icon(_ request: PullRequestSummary) -> String {
        switch request.state {
        case .merged: "arrow.triangle.merge"
        case .closed: "xmark.circle"
        default: "arrow.triangle.pull"
        }
    }

    private static func tint(_ request: PullRequestSummary) -> Tint {
        switch request.state {
        case .merged: .purple
        case .closed: .secondary
        default: request.isDraft ? .gray : .blue
        }
    }

    private static func stateTitle(_ request: PullRequestSummary) -> String {
        if request.isDraft, request.state == .opened { return "Draft" }
        switch request.state {
        case .opened: return "Open"
        case .merged: return "Merged"
        case .closed: return "Closed"
        default: return request.state.name.capitalized
        }
    }
}
