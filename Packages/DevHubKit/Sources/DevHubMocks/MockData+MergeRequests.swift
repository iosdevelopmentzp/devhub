import Foundation
import DevHubDomain

package extension MockData {
    static let gitLabUsername = "alex"

    static let mergeRequests: [MergeRequestSummary] = [
        mergeRequest(1842, "ABC-2324: Paid call payment", author: "alex", source: "feature/ABC-2324-paid-call", detail: .notApproved, pipeline: .running, labels: ["feature"], comments: 4, minutesAgo: 12, diff: (120, 30, 7, 3), threads: (3, 1), behind: true),
        mergeRequest(1839, "ABC-2311: Leaderboard pagination", author: "sam", source: "feature/ABC-2311-leaderboard", detail: .mergeable, pipeline: .success, approvedBy: ["kim"], labels: ["feature"], comments: 9, minutesAgo: 95, diff: (48, 12, 4, 2), threads: (2, 2)),
        mergeRequest(1836, "Draft: ABC-2290: New onboarding", author: "kim", source: "feature/ABC-2290-onboarding", isDraft: true, detail: .draftStatus, pipeline: .failed, labels: ["tech"], comments: 0, minutesAgo: 300, diff: (900, 340, 31, 14)),
        mergeRequest(1830, "ABC-2280: Fix chat crash on iOS 17", author: "robin", source: "fix/ABC-2280-chat-crash", conflicts: true, detail: .needRebase, pipeline: .success, labels: ["bug"], comments: 2, minutesAgo: 1_500, diff: (6, 2, 1, 1), behind: true),
        mergeRequest(1825, "ABC-2266: Remove old analytics", author: "sam", source: "feature/ABC-2266-analytics", target: "release/4.13", detail: .discussionsNotResolved, pipeline: nil, approvedBy: ["alex"], labels: ["tech"], comments: 17, minutesAgo: 30_000, diff: (15, 410, 22, 5), threads: (6, 2)),
        mergeRequest(1810, "ABC-2201: Release 4.12", author: "sam", source: "release/4.12", state: .merged, target: "main", detail: nil, pipeline: .success, approvedBy: ["alex", "kim"], labels: [], comments: 3, minutesAgo: 9_000, diff: (60, 8, 5, 3), mergedBy: "kim"),
    ]

    static let mergeRequestDetails = MergeRequestDetails(
        description: "Adds **paid calls**.\n\n- Payment sheet before the call\n- Retry when the payment fails\n\nTicket: ABC-2324",
        threads: [
            MergeRequestThread(
                id: "1",
                noteID: 501,
                author: "sam",
                body: "Please move this check into the presenter.",
                filePath: "ExampleUI/Calls/CallPresenter.swift",
                line: 42,
                isOnOldLine: false,
                replies: [MergeRequestNote(author: "alex", body: "Done in the next commit."), MergeRequestNote(author: "sam", body: "Thanks!")]
            ),
            MergeRequestThread(id: "2", noteID: 502, author: "kim", body: "Do we need a test for the retry?", filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ]
    )

    static let mergeRequestDiffs: [MergeRequestFileDiff] = [
        MergeRequestFileDiff(
            oldPath: "ExampleUI/Calls/CallPresenter.swift",
            path: "ExampleUI/Calls/CallPresenter.swift",
            kind: .modified,
            additions: 2,
            deletions: 1,
            diff: GitDiff(lines: ["@@ -40,3 +40,4 @@ final class CallPresenter {", "     func start() {", "-        call()", "+        guard isPaid else { return pay() }", "+        call()"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
        MergeRequestFileDiff(
            oldPath: "ExampleUI/Calls/PaymentSheet.swift",
            path: "ExampleUI/Calls/PaymentSheet.swift",
            kind: .added,
            additions: 2,
            deletions: 0,
            diff: GitDiff(lines: ["@@ -0,0 +1,2 @@", "+import SwiftUI", "+struct PaymentSheet: View {}"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
    ]

    private static func mergeRequest(
        _ iid: Int,
        _ title: String,
        author: String,
        source: String,
        state: MergeRequestState = .opened,
        target: String = "dev",
        isDraft: Bool = false,
        conflicts: Bool = false,
        detail: MergeDetail?,
        pipeline: PipelineStatus?,
        approvedBy: [String] = [],
        labels: [String],
        comments: Int,
        minutesAgo: Double,
        diff: (additions: Int, deletions: Int, files: Int, commits: Int),
        threads: (total: Int, resolved: Int) = (0, 0),
        behind: Bool = false,
        mergedBy: String? = nil
    ) -> MergeRequestSummary {
        MergeRequestSummary(
            iid: iid,
            title: title,
            state: state,
            isDraft: isDraft,
            webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/\(iid)"),
            author: author,
            sourceBranch: source,
            targetBranch: target,
            hasConflicts: conflicts,
            detailedStatus: detail,
            commentCount: comments,
            updatedAt: Date(timeIntervalSinceNow: -minutesAgo * 60),
            pipeline: pipeline.map {
                PipelineInfo(
                    status: $0,
                    webURL: URL(string: "https://gitlab.com/example/app/-/pipelines/\(iid)"),
                    updatedAt: Date(timeIntervalSinceNow: -minutesAgo * 60),
                    id: iid * 10,
                    duration: 540,
                    failedJobCount: $0 == .failed ? 2 : 0
                )
            },
            approvedBy: approvedBy,
            labels: labels,
            createdAt: Date(timeIntervalSinceNow: -(minutesAgo + 7_200) * 60),
            mergedAt: state == .merged ? Date(timeIntervalSinceNow: -minutesAgo * 60) : nil,
            mergedBy: mergedBy,
            commitCount: diff.commits,
            diffStats: DiffStats(additions: diff.additions, deletions: diff.deletions, fileCount: diff.files),
            threadCount: threads.total,
            resolvedThreadCount: threads.resolved,
            isBehindTarget: behind,
            squashOnMerge: true,
            removesSourceBranch: true,
            headSHA: "9f3c2a1\(iid)",
            isAutoMergeEnabled: false,
            permissions: MergeRequestPermissions(canMerge: true, canApprove: author != gitLabUsername)
        )
    }
}
