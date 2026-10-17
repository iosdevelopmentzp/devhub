import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabGraphQLParserTests {
    @Test func projectListMapsEveryField() throws {
        let list = try GlabGraphQLParser.list(from: GlabGraphQLFixture.projectList, host: "gitlab.example.com")

        #expect(list.username == "me")
        #expect(list.totalCount == 250)
        #expect(list.hasNextPage)
        #expect(list.endCursor == "eyJpZCI6IjIwIn0")
        #expect(list.requests.count == 2)
        #expect(list.requests[0] == MergeRequestSummary(
            iid: 21,
            title: "ABC-5: Login",
            state: .opened,
            isDraft: false,
            webURL: URL(string: "https://gitlab.example.com/team/app/-/merge_requests/21"),
            author: "sam",
            sourceBranch: "feature/login",
            targetBranch: "dev",
            hasConflicts: true,
            detailedStatus: .notApproved,
            commentCount: 3,
            updatedAt: ISO8601.date(from: "2026-01-02T03:04:05Z"),
            pipeline: PipelineInfo(
                status: .failed,
                webURL: URL(string: "https://gitlab.example.com/team/app/-/pipelines/9"),
                updatedAt: ISO8601.date(from: "2026-01-02T03:00:00Z"),
                id: 9,
                duration: 540,
                finishedAt: ISO8601.date(from: "2026-01-02T03:09:00Z"),
                failedJobCount: 2
            ),
            approvedBy: ["kim"],
            labels: ["feature"],
            createdAt: ISO8601.date(from: "2025-12-20T10:00:00Z"),
            mergedAt: nil,
            closedAt: nil,
            mergedBy: nil,
            commitCount: 4,
            diffStats: DiffStats(additions: 120, deletions: 30, fileCount: 7),
            threadCount: 5,
            resolvedThreadCount: 2,
            isBehindTarget: true,
            squashOnMerge: true,
            removesSourceBranch: false,
            headSHA: "abc123",
            isAutoMergeEnabled: true,
            permissions: MergeRequestPermissions(canMerge: true, canApprove: false)
        ))
        #expect(list.requests[0].openThreadCount == 3)
        let old = list.requests[1]
        #expect(old.state == .merged)
        #expect(old.pipeline == nil)
        #expect(old.author == "")
        #expect(old.approvedBy.isEmpty)
        #expect(old.labels.isEmpty)
        #expect(old.mergedBy == "kim")
        #expect(old.mergedAt == ISO8601.date(from: "2026-01-01T09:00:00Z"))
    }

    @Test func missingNewFieldsFallBackToDefaults() throws {
        let list = try GlabGraphQLParser.list(from: GlabGraphQLFixture.authoredList, host: "h")
        let request = try #require(list.requests.first)

        #expect(request.diffStats == nil)
        #expect(request.commitCount == nil)
        #expect(request.openThreadCount == 0)
        #expect(request.isBehindTarget == false)
        #expect(request.removesSourceBranch == nil)
        #expect(request.isAutoMergeEnabled == false)
        #expect(request.permissions == .none)
    }

    @Test func currentUserListsAreRead() throws {
        let authored = try GlabGraphQLParser.list(from: GlabGraphQLFixture.authoredList, host: "h")
        let assigned = try GlabGraphQLParser.list(from: GlabGraphQLFixture.assignedList, host: "h")

        #expect(authored.requests.map(\.iid) == [5])
        #expect(authored.hasNextPage == false)
        #expect(authored.endCursor == nil)
        #expect(assigned.requests.isEmpty)
        #expect(assigned.username == "me")
    }

    @Test func missingUserMeansNotLoggedIn() {
        #expect(throws: MergeRequestError.notLoggedIn(host: "h")) {
            try GlabGraphQLParser.list(from: GlabGraphQLFixture.noUser, host: "h")
        }
    }

    @Test func errorsNextToDataKeepTheData() throws {
        let list = try GlabGraphQLParser.list(from: GlabGraphQLFixture.partialFailure, host: "h")

        #expect(list.requests.map(\.iid) == [5])
    }

    @Test func missingProjectAndErrorsThrow() {
        #expect(throws: MergeRequestError.command("GitLab did not find the project")) {
            try GlabGraphQLParser.list(from: GlabGraphQLFixture.noProject, host: "h")
        }
        #expect(throws: MergeRequestError.command("Field 'x' doesn't exist")) {
            try GlabGraphQLParser.list(from: GlabGraphQLFixture.failure, host: "h")
        }
    }

    @Test func detailsKeepOnlyOpenThreadsAndSkipSystemNotes() throws {
        let details = try GlabGraphQLParser.details(from: GlabGraphQLFixture.details, host: "gitlab.example.com")

        #expect(details.description == "Adds **login**.")
        #expect(details.threads == [
            MergeRequestThread(id: "d1", noteID: 11, author: "sam", body: "Move this", filePath: "App/Login.swift", line: 12, isOnOldLine: true, replies: [MergeRequestNote(author: "me", body: "Done?")]),
            MergeRequestThread(id: "d4", noteID: 44, author: "kim", body: "Need a test", filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ])
    }

    @Test func detailsReadTheFailedJobsAndThePipelineDuration() throws {
        let details = try GlabGraphQLParser.details(from: GlabGraphQLFixture.details, host: "gitlab.example.com")

        #expect(details.pipelineDuration == 540)
        #expect(details.failedJobs == [
            PipelineJob(name: "build-ios", stage: "test", webURL: URL(string: "https://gitlab.example.com/team/app/-/jobs/71")),
            PipelineJob(name: "lint", stage: nil, webURL: nil),
        ])
    }

    @Test func detailsWithoutAPipelineHaveNoJobs() throws {
        let data = Data(#"{"data":{"project":{"mergeRequest":{"description":null,"headPipeline":null,"discussions":{"nodes":[]}}}}}"#.utf8)

        let details = try GlabGraphQLParser.details(from: data, host: "h")

        #expect(details.failedJobs.isEmpty)
        #expect(details.pipelineDuration == nil)
    }

    @Test func autoMergePayloadReportsTheRefusal() throws {
        try GlabGraphQLParser.mutation(from: GlabGraphQLFixture.autoMergeAccepted)

        #expect(throws: MergeRequestError.command("SHA does not match HEAD of source branch")) {
            try GlabGraphQLParser.mutation(from: GlabGraphQLFixture.autoMergeRefused)
        }
    }

    @Test func mutationErrorsAreReported() throws {
        try GlabGraphQLParser.mutation(from: Data(#"{"data":{"mergeRequestSetDraft":{"errors":[]}}}"#.utf8))

        #expect(throws: MergeRequestError.command("Not allowed")) {
            try GlabGraphQLParser.mutation(from: Data(#"{"data":{"mergeRequestSetDraft":{"errors":["Not allowed"]}}}"#.utf8))
        }
        #expect(throws: MergeRequestError.command("Field 'x' doesn't exist")) {
            try GlabGraphQLParser.mutation(from: GlabGraphQLFixture.failure)
        }
    }

    @Test func labelsAreSortedByName() throws {
        #expect(try GlabGraphQLParser.labels(from: GlabGraphQLFixture.labels) == ["ADR", "bugfix", "tech"])
        #expect(throws: MergeRequestError.command("GitLab did not find the project")) {
            try GlabGraphQLParser.labels(from: GlabGraphQLFixture.noProject)
        }
    }

    @Test func missingMergeRequestThrows() {
        #expect(throws: MergeRequestError.command("GitLab did not find the merge request")) {
            try GlabGraphQLParser.details(from: GlabGraphQLFixture.noMergeRequest, host: "h")
        }
    }
}
