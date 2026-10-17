import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestCompactRowMapperTests {
    @Test func signalsAreIconsWithCountsAndColourOnlyForProblems() {
        let request = PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: .opened,
            author: "sam",
            hasConflicts: true,
            pipeline: PipelineInfo(status: .success, webURL: nil, updatedAt: nil),
            approvedBy: ["lee", "kim"],
            threadCount: 3,
            resolvedThreadCount: 1
        )

        let signals = PullRequestCompactRowMapper.signals(for: request, username: "me", scope: .all)

        #expect(signals.map(\.systemImage) == ["exclamationmark.triangle.fill", "eye", "checkmark.circle.fill", "checkmark.seal", "bubble.left.and.bubble.right"])
        #expect(signals.map(\.text) == ["", "", "", "2", "2"])
        #expect(signals.map(\.tint) == [.red, .indigo, .secondary, .secondary, .secondary])
    }

    @Test func aFailedPipelineStaysRed() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil))

        let signals = PullRequestCompactRowMapper.signals(for: request, username: "me", scope: .mine)

        #expect(signals.map(\.tint) == [.red])
    }

    @Test func aDraftSaysSoAndAClosedRequestHasNoOpenSignals() {
        let draft = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", isDraft: true)
        let merged = PullRequestSummaryFixture.request(iid: 8, source: "y", state: .merged, author: "sam", hasConflicts: true, threadCount: 2)

        #expect(PullRequestCompactRowMapper.signals(for: draft, username: "me", scope: .mine).map(\.text) == ["draft"])
        #expect(PullRequestCompactRowMapper.signals(for: merged, username: "me", scope: .all).isEmpty)
    }

    @Test func modelTakesTheRowFactsAndHidesTheAuthorInMine() {
        let request = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", updatedAt: Date(timeIntervalSinceNow: -60))
        let row = PullRequestRowModel.preview
        let context = PullRequestRowContext(username: "me", scope: .mine, seenAt: nil, now: .now, isMainCheckoutClean: true, ticket: .standard)

        let model = PullRequestCompactRowMapper.model(for: request, row: row, context: context)

        #expect(model.id == row.id)
        #expect(model.reference == row.reference)
        #expect(model.title == row.title)
        #expect(model.isNew == row.isNew)
        #expect(model.author == "")
        #expect(model.dateText?.isEmpty == false)
    }
}
