import Foundation
import DevHubDomain
import DevHubUI

enum MergeRequestCompactRowMapper {

    static func model(for request: MergeRequestSummary, row: MergeRequestRowModel, context: MergeRequestRowContext) -> MergeRequestCompactRowModel {
        MergeRequestCompactRowModel(
            id: row.id,
            reference: row.reference,
            title: row.title,
            icon: row.icon,
            iconTint: row.iconTint,
            iconHint: row.iconHint,
            isNew: row.isNew,
            signals: signals(for: request, username: context.username, scope: context.scope),
            author: context.scope == .mine ? "" : request.author,
            authorTint: row.authorTint,
            dateText: (request.mergedAt ?? request.closedAt ?? request.updatedAt)?.relativeDescription,
            webURL: row.webURL,
            linkText: row.linkText
        )
    }

    static func signals(for request: MergeRequestSummary, username: String?, scope: MergeRequestScope) -> [TagModel] {
        let isOpen = request.state == .opened
        var signals: [TagModel] = []
        if request.isDraft, isOpen {
            signals.append(TagModel("draft", tint: .secondary, hint: "Draft: not ready for review"))
        }
        if request.hasConflicts, isOpen {
            signals.append(.icon("exclamationmark.triangle.fill", tint: .red, hint: MergeRequestTagMapper.conflictsTag(targetBranch: request.targetBranch).hint))
        }
        if scope != .reviewing, isOpen, let username, ReviewQueuePolicy.needsMyReview(request, username: username) {
            signals.append(.icon("eye", tint: .indigo, hint: "Needs your review"))
        }
        if let pipeline = request.pipeline {
            let tag = MergeRequestTagMapper.compactPipelineTag(pipeline)
            signals.append(MergeRequestCalmStyleMapper.quiet(.icon(tag.systemImage ?? "circle", tint: tag.tint, hint: tag.hint)))
        }
        if request.isAutoMergeEnabled, isOpen {
            signals.append(.icon("clock.badge.checkmark", tint: .secondary, hint: "Merges when the pipeline passes"))
        }
        if let approval = MergeRequestTagMapper.approvalTag(approvedBy: request.approvedBy, username: username) {
            signals.append(TagModel("\(request.approvedBy.count)", tint: .secondary, systemImage: "checkmark.seal", hint: approval.hint))
        }
        if isOpen, let threads = MergeRequestTagMapper.openThreadsTag(open: request.openThreadCount, total: request.threadCount, comments: request.commentCount) {
            signals.append(TagModel("\(request.openThreadCount)", tint: .secondary, systemImage: "bubble.left.and.bubble.right", hint: "\(threads.text). \(threads.hint ?? "")"))
        }
        return signals
    }
}
