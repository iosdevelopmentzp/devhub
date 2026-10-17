import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestCompactRowMapperTests {
    @Test func signalsAreIconsWithCountsAndColourOnlyForProblems() {
        let request = MergeRequestSummaryFixture.request(
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

        let signals = MergeRequestCompactRowMapper.signals(for: request, username: "me", scope: .all)

        #expect(signals.map(\.systemImage) == ["exclamationmark.triangle.fill", "eye", "checkmark.circle.fill", "checkmark.seal", "bubble.left.and.bubble.right"])
        #expect(signals.map(\.text) == ["", "", "", "2", "2"])
        #expect(signals.map(\.tint) == [.red, .indigo, .secondary, .secondary, .secondary])
    }

    @Test func aFailedPipelineStaysRed() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil))

        let signals = MergeRequestCompactRowMapper.signals(for: request, username: "me", scope: .mine)

        #expect(signals.map(\.tint) == [.red])
    }

    @Test func aDraftSaysSoAndAClosedRequestHasNoOpenSignals() {
        let draft = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", isDraft: true)
        let merged = MergeRequestSummaryFixture.request(iid: 8, source: "y", state: .merged, author: "sam", hasConflicts: true, threadCount: 2)

        #expect(MergeRequestCompactRowMapper.signals(for: draft, username: "me", scope: .mine).map(\.text) == ["draft"])
        #expect(MergeRequestCompactRowMapper.signals(for: merged, username: "me", scope: .all).isEmpty)
    }

    @Test func modelTakesTheRowFactsAndHidesTheAuthorInMine() {
        let request = MergeRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "me", updatedAt: Date(timeIntervalSinceNow: -60))
        let row = MergeRequestRowModel.preview
        let context = MergeRequestRowContext(username: "me", scope: .mine, seenAt: nil, now: .now, isMainCheckoutClean: true, ticketURLTemplate: "")

        let model = MergeRequestCompactRowMapper.model(for: request, row: row, context: context)

        #expect(model.id == row.id)
        #expect(model.reference == row.reference)
        #expect(model.title == row.title)
        #expect(model.isNew == row.isNew)
        #expect(model.author == "")
        #expect(model.dateText?.isEmpty == false)
    }
}
