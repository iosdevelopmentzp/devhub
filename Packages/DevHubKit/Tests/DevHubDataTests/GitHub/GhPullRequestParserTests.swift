import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhPullRequestParserTests {
    @Test func listMapsEveryField() throws {
        let list = try GhPullRequestParser.list(from: GhFixture.list)

        #expect(list.username == "alex")
        #expect(list.totalCount == 3)
        #expect(list.hasNextPage == false)
        #expect(list.endCursor == "Y3Vyc29yOjM=")
        #expect(list.requests.map(\.iid) == [3, 1, 2])
        #expect(list.requests[1] == PullRequestSummary(
            iid: 1,
            title: "ABC-101: Login screen",
            state: .opened,
            isDraft: false,
            webURL: URL(string: "https://github.com/example/app/pull/1"),
            author: "alex",
            sourceBranch: "feature/ABC-101-login",
            targetBranch: "main",
            hasConflicts: false,
            detailedStatus: .mergeable,
            commentCount: 2,
            updatedAt: ISO8601.date(from: "2026-10-17T22:33:02Z"),
            pipeline: PipelineInfo(
                status: .success,
                webURL: URL(string: "https://github.com/example/app/pull/1/checks"),
                updatedAt: ISO8601.date(from: "2026-10-17T22:33:16Z"),
                id: 901,
                duration: 5,
                finishedAt: ISO8601.date(from: "2026-10-17T22:33:16Z"),
                failedJobCount: 0
            ),
            approvedBy: [],
            labels: ["feature"],
            assignees: ["sam"],
            reviewers: ["kim"],
            createdAt: ISO8601.date(from: "2026-10-17T22:30:37Z"),
            mergedAt: nil,
            closedAt: nil,
            mergedBy: nil,
            commitCount: 2,
            diffStats: DiffStats(additions: 3, deletions: 1, fileCount: 2),
            threadCount: 1,
            resolvedThreadCount: 0,
            isBehindTarget: false,
            squashOnMerge: false,
            removesSourceBranch: false,
            headSHA: "aaa111",
            isAutoMergeEnabled: false,
            permissions: PullRequestPermissions(canMerge: true, canApprove: false, canRevokeApproval: true, canSetAutoMerge: false, canRequestChanges: false)
        ))
    }

    @Test func aFailedCheckLinksToTheFailedJob() throws {
        let request = try #require(try GhPullRequestParser.list(from: GhFixture.list).requests.first)
        let pipeline = try #require(request.pipeline)

        #expect(pipeline.status == .failed)
        #expect(pipeline.id == 903)
        #expect(pipeline.failedJobCount == 1)
        #expect(pipeline.webURL == URL(string: "https://github.com/example/app/actions/runs/903/job/9031"))
        #expect(request.detailedStatus == .mergeable)
    }

    @Test func aDraftHasTheDraftStatusAndNoChecks() throws {
        let request = try #require(try GhPullRequestParser.list(from: GhFixture.list).requests.last)

        #expect(request.isDraft)
        #expect(request.detailedStatus == .draftStatus)
        #expect(request.pipeline == nil)
    }

    @Test func statusTakesTheOpenRequestAndTheBranchChecks() throws {
        let status = try GhPullRequestParser.status(from: GhFixture.status)
        let request = try #require(status.pullRequest)

        #expect(request.iid == 3)
        #expect(request.state == .opened)
        #expect(request.targetBranch == "main")
        #expect(status.pipeline?.status == .failed)
        #expect(status.pipeline?.id == 903)
    }

    @Test func detailsListOpenThreadsWithTheirLine() throws {
        let details = try GhPullRequestParser.details(from: GhFixture.threadDetails)

        #expect(details.description == "Adds the login notes.")
        #expect(details.threads == [
            ReviewThread(
                id: "PRRT_thread1",
                noteID: 4301,
                author: "alex",
                body: "Please rename this line.",
                createdAt: ISO8601.date(from: "2026-10-17T22:41:40Z"),
                filePath: "notes.txt",
                line: 2,
                isOnOldLine: false,
                replies: [PullRequestNote(author: "sam", body: "Done.", createdAt: ISO8601.date(from: "2026-10-17T22:41:47Z"))]
            ),
        ])
        #expect(details.failedJobs.isEmpty)
        #expect(details.pipelineDuration == 5)
    }

    @Test func aReviewThatAsksForChangesNamesItsAuthor() throws {
        let list = try GhPullRequestParser.list(from: GhFixture.list)

        #expect(list.requests[0].changesRequestedBy == ["kim"])
        #expect(list.requests[1].changesRequestedBy.isEmpty)
    }

    @Test func detailsListTheFailedJobs() throws {
        let details = try GhPullRequestParser.details(from: GhFixture.failedDetails)

        #expect(details.failedJobs == [PipelineJob(name: "notes", stage: nil, webURL: URL(string: "https://github.com/example/app/actions/runs/903/job/9031"))])
        #expect(details.pipelineDuration == 7)
        #expect(details.jobs == [
            PipelineJob(
                name: "notes",
                stage: "Check",
                webURL: URL(string: "https://github.com/example/app/actions/runs/903/job/9031"),
                id: "9031",
                status: .failed,
                duration: 7,
                failureMessage: "Process completed with exit code 1."
            ),
        ])
    }

    @Test func myApprovalIsTheReviewOfTheViewer() throws {
        #expect(try GhPullRequestParser.myApprovalID(from: GhFixture.myApproval) == "PRR_mine")
    }

    @Test func labelsAreSortedByName() throws {
        #expect(try GhPullRequestParser.labels(from: GhFixture.labels) == ["bug", "Feature", "tech"])
    }

    @Test func aMutationErrorThrowsItsMessage() throws {
        #expect(throws: PullRequestError.command("Could not resolve to a node with the global id of 'x'")) {
            try GhPullRequestParser.mutation(from: GhFixture.mutationFailed)
        }
        try GhPullRequestParser.mutation(from: GhFixture.mutationDone)
    }

    @Test func aMissingRepositoryIsACommandError() {
        #expect(throws: PullRequestError.command("GitHub did not find the repository")) {
            try GhPullRequestParser.status(from: Data(#"{"data":{"repository":null}}"#.utf8))
        }
    }

    @Test func theCreatedRequestIsParsed() throws {
        let summary = try GhCreatedPullRequestParser.summary(from: GhFixture.created, labels: ["feature"])

        #expect(summary.iid == 4)
        #expect(summary.isDraft)
        #expect(summary.state == .opened)
        #expect(summary.webURL == URL(string: "https://github.com/example/app/pull/4"))
        #expect(summary.sourceBranch == "feature/ABC-104")
        #expect(summary.targetBranch == "main")
        #expect(summary.labels == ["feature"])
        #expect(summary.headSHA == "ddd444")
    }
}
