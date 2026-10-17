import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct RequestLinkTextTests {
    @Test func referenceTitleAndLinkOnTwoLines() {
        let request = PullRequestSummaryFixture.request(iid: 1396, source: "x", state: .opened, title: "ABC-2200: Add Follow Top Streamers step to the onboarding")

        #expect(RequestLinkText.pullRequest(request) == "!1396 ABC-2200: Add Follow Top Streamers step to the onboarding\nhttps://gitlab.example.com/team/app/-/merge_requests/1396")
    }

    @Test func withoutALinkOnlyTheFirstLine() {
        #expect(RequestLinkText.pullRequest(iid: 3, title: "Fix", url: nil) == "!3 Fix")
    }
}
