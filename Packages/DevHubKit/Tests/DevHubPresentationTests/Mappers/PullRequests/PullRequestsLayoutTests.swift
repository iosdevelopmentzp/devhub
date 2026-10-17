import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestsLayoutTests {
    @Test func narrowContentKeepsTheInlineDetails() {
        #expect(PullRequestsLayout.layout(forWidth: 720, listFraction: 0.42) == .inline)
        #expect(PullRequestsLayout.layout(forWidth: 959, listFraction: 0.42) == .inline)
    }

    @Test func wideContentSplitsTheListAndTheDetails() {
        #expect(PullRequestsLayout.layout(forWidth: 1200, listFraction: 0.42) == .split(listWidth: 504))
        #expect(PullRequestsLayout.layout(forWidth: 1200, listFraction: 0.42).isSplit)
        #expect(PullRequestsLayout.layout(forWidth: 700, listFraction: 0.42).isSplit == false)
    }

    @Test func theListKeepsItsMinimumAndLeavesRoomForTheDetails() {
        #expect(PullRequestsLayout.layout(forWidth: 1000, listFraction: 0.1) == .split(listWidth: 320))
        #expect(PullRequestsLayout.layout(forWidth: 1000, listFraction: 0.9) == .split(listWidth: 560))
    }

    @Test func aDraggedWidthBecomesAClampedFraction() {
        #expect(PullRequestsLayout.fraction(forListWidth: 500, in: 1000) == 0.5)
        #expect(PullRequestsLayout.fraction(forListWidth: 100, in: 1000) == 0.32)
        #expect(PullRequestsLayout.fraction(forListWidth: 900, in: 1000) == 0.56)
    }
}
