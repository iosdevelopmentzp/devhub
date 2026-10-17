import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct GitLabLayoutTests {
    @Test func narrowContentKeepsTheInlineDetails() {
        #expect(GitLabLayout.layout(forWidth: 720, listFraction: 0.42) == .inline)
        #expect(GitLabLayout.layout(forWidth: 959, listFraction: 0.42) == .inline)
    }

    @Test func wideContentSplitsTheListAndTheDetails() {
        #expect(GitLabLayout.layout(forWidth: 1200, listFraction: 0.42) == .split(listWidth: 504))
        #expect(GitLabLayout.layout(forWidth: 1200, listFraction: 0.42).isSplit)
        #expect(GitLabLayout.layout(forWidth: 700, listFraction: 0.42).isSplit == false)
    }

    @Test func theListKeepsItsMinimumAndLeavesRoomForTheDetails() {
        #expect(GitLabLayout.layout(forWidth: 1000, listFraction: 0.1) == .split(listWidth: 320))
        #expect(GitLabLayout.layout(forWidth: 1000, listFraction: 0.9) == .split(listWidth: 560))
    }

    @Test func aDraggedWidthBecomesAClampedFraction() {
        #expect(GitLabLayout.fraction(forListWidth: 500, in: 1000) == 0.5)
        #expect(GitLabLayout.fraction(forListWidth: 100, in: 1000) == 0.32)
        #expect(GitLabLayout.fraction(forListWidth: 900, in: 1000) == 0.56)
    }
}
