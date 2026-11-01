import DevHubDomain
import DevHubUI
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestExplainMapperTests {
    private let summary = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened)

    private func context(explanations: [Int: String] = [:], running: Set<Int> = []) -> PullRequestRowContext {
        PullRequestRowContext(username: "alex", scope: .all, seenAt: nil, now: .now, isMainCheckoutClean: true, ticket: .standard, words: .gitLab, staleDays: 14, hiddenFiles: [], watchedIDs: [], explanations: explanations, explainingIDs: running, aiProvider: .claude)
    }

    @Test func beforeTheFirstRunTheButtonSaysExplain() {
        let model = PullRequestExplainMapper.model(summary: summary, review: .initial, context: context())

        #expect(model.button.title == "Explain")
        #expect(model.button.hint.contains("merge request"))
        #expect(model.button.hint.contains("since your review") == false)
        #expect(model.text == nil)
    }

    @Test func anAnswerShowsWithBoldHeadings() throws {
        let model = PullRequestExplainMapper.model(summary: summary, review: .initial, context: context(explanations: [7: "## Risky places\n- `start()`"]))

        let text = try #require(model.text)
        #expect(model.button.title == "Explain Again")
        #expect(String(text.characters).hasPrefix("Risky places"))
    }

    @Test func aReviewedRequestMentionsTheChanges() {
        var review = PullRequestReviewState.initial
        review.changedSinceReview = ["a.swift"]

        let model = PullRequestExplainMapper.model(summary: summary, review: review, context: context(running: [7]))

        #expect(model.button.isRunning)
        #expect(model.button.hint.contains("what changed since your review"))
    }
}
