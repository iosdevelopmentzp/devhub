import Foundation
import DevHubDomain

package extension MockData {
    static let gitLabUsername = "alex"

    static let pullRequests: [PullRequestSummary] = [
        pullRequest(1842, "ABC-2324: Paid call payment", author: "alex", source: "feature/ABC-2324-paid-call", detail: .notApproved, pipeline: .running, approvedBy: ["robin"], labels: ["feature"], assignees: ["alex"], reviewers: ["sam", "kim", "robin"], changesRequestedBy: ["kim"], comments: 4, minutesAgo: 12, diff: (120, 30, 7, 3), threads: (3, 1), behind: true),
        pullRequest(1839, "ABC-2311: Leaderboard pagination", author: "sam", source: "feature/ABC-2311-leaderboard", detail: .mergeable, pipeline: .success, approvedBy: ["kim"], labels: ["feature"], reviewers: ["kim"], comments: 9, minutesAgo: 95, diff: (48, 12, 4, 2), threads: (2, 2)),
        pullRequest(1836, "Draft: ABC-2290: New onboarding", author: "kim", source: "feature/ABC-2290-onboarding", isDraft: true, detail: .draftStatus, pipeline: .failed, labels: ["tech"], comments: 0, minutesAgo: 300, diff: (900, 340, 31, 14)),
        pullRequest(1830, "ABC-2280: Fix chat crash on iOS 17", author: "robin", source: "fix/ABC-2280-chat-crash", conflicts: true, detail: .needRebase, pipeline: .success, labels: ["bug"], comments: 2, minutesAgo: 1_500, diff: (6, 2, 1, 1), behind: true),
        pullRequest(1825, "ABC-2266: Remove old analytics", author: "sam", source: "feature/ABC-2266-analytics", target: "release/4.13", detail: .discussionsNotResolved, pipeline: nil, approvedBy: ["alex"], labels: ["tech"], comments: 17, minutesAgo: 30_000, diff: (15, 410, 22, 5), threads: (6, 2)),
        pullRequest(1810, "ABC-2201: Release 4.12", author: "sam", source: "release/4.12", state: .merged, target: "main", detail: nil, pipeline: .success, approvedBy: ["alex", "kim"], labels: [], comments: 3, minutesAgo: 9_000, diff: (60, 8, 5, 3), mergedBy: "kim"),
    ]

    static let pullRequestDetails = PullRequestDetails(
        description: "Adds **paid calls**.\n\n- Payment sheet before the call\n- Retry when the payment fails\n\nTicket: ABC-2324",
        threads: [
            ReviewThread(
                id: "1",
                noteID: 501,
                author: "sam",
                body: "Please move this check into the presenter.\n\nThe view should not know about `isPaid`; the presenter already has the account state.",
                createdAt: Date(timeIntervalSinceNow: -3 * 3_600),
                filePath: "ExampleUI/Calls/CallPresenter.swift",
                line: 42,
                isOnOldLine: false,
                replies: [
                    PullRequestNote(author: "alex", body: "Done in the next commit.", createdAt: Date(timeIntervalSinceNow: -2 * 3_600)),
                    PullRequestNote(author: "sam", body: "Thanks!", createdAt: Date(timeIntervalSinceNow: -3_600)),
                ]
            ),
            ReviewThread(id: "2", noteID: 502, author: "kim", body: "Do we need a test for the retry?", createdAt: Date(timeIntervalSinceNow: -40 * 60), filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ],
        pipelineDuration: 540,
        jobs: [
            PipelineJob(name: "build", stage: "build", webURL: URL(string: "https://gitlab.com/example/app/-/jobs/70"), id: "70", status: .success, duration: 310),
            PipelineJob(name: "unit-tests", stage: "test", webURL: URL(string: "https://gitlab.com/example/app/-/jobs/71"), id: "71", status: .failed, duration: 130, failureMessage: "The script exited with code 65"),
            PipelineJob(name: "lint", stage: "test", webURL: URL(string: "https://gitlab.com/example/app/-/jobs/72"), id: "72", status: .failed, duration: 40, allowsFailure: true),
            PipelineJob(name: "ui-tests", stage: "test", webURL: URL(string: "https://gitlab.com/example/app/-/jobs/73"), id: "73", status: .running),
            PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: "https://app.circleci.example.com/pipelines/github/example/app/42/workflows/" + ciWorkflowID + "/jobs/7"), id: nil, status: .failed, ciWorkflowID: ciWorkflowID),
        ]
    )

    static let pullRequestDiffs: [PullRequestFileDiff] = [
        PullRequestFileDiff(
            oldPath: "ExampleUI/Calls/CallPresenter.swift",
            path: "ExampleUI/Calls/CallPresenter.swift",
            kind: .modified,
            additions: 2,
            deletions: 1,
            diff: GitDiff(lines: ["@@ -40,3 +40,4 @@ final class CallPresenter {", "     func start() {", "-        call()", "+        guard isPaid else { return pay() }", "+        call()"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
        PullRequestFileDiff(
            oldPath: "ExampleUI/Calls/PaymentSheet.swift",
            path: "ExampleUI/Calls/PaymentSheet.swift",
            kind: .added,
            additions: 2,
            deletions: 0,
            diff: GitDiff(lines: ["@@ -0,0 +1,2 @@", "+import SwiftUI", "+struct PaymentSheet: View {}"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
        PullRequestFileDiff(
            oldPath: "ExampleUITests/Calls/CallPresenterTests.swift",
            path: "ExampleUITests/Calls/CallPresenterTests.swift",
            kind: .modified,
            additions: 12,
            deletions: 0,
            diff: GitDiff(lines: ["@@ -10,0 +10,2 @@", "+    func testPaidCallAsksForPayment() {", "+    }"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
        PullRequestFileDiff(
            oldPath: "ExampleApp.xcodeproj/project.pbxproj",
            path: "ExampleApp.xcodeproj/project.pbxproj",
            kind: .modified,
            additions: 8,
            deletions: 0,
            diff: GitDiff(lines: ["@@ -100,0 +100,1 @@", "+\t\t1A2B /* PaymentSheet.swift */ = {isa = PBXFileReference;};"], droppedLines: 0, isBinary: false),
            isTooLarge: false
        ),
    ]

    private static func pullRequest(
        _ iid: Int,
        _ title: String,
        author: String,
        source: String,
        state: PullRequestState = .opened,
        target: String = "dev",
        isDraft: Bool = false,
        conflicts: Bool = false,
        detail: MergeReadiness?,
        pipeline: CheckStatus?,
        approvedBy: [String] = [],
        labels: [String],
        assignees: [String] = [],
        reviewers: [String] = [],
        changesRequestedBy: [String] = [],
        comments: Int,
        minutesAgo: Double,
        diff: (additions: Int, deletions: Int, files: Int, commits: Int),
        threads: (total: Int, resolved: Int) = (0, 0),
        behind: Bool = false,
        mergedBy: String? = nil
    ) -> PullRequestSummary {
        PullRequestSummary(
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
            assignees: assignees,
            reviewers: reviewers,
            changesRequestedBy: changesRequestedBy,
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
            permissions: PullRequestPermissions(canMerge: true, canApprove: author != gitLabUsername, canRevokeApproval: true, canSetAutoMerge: true)
        )
    }
}
