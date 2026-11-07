import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestReviewMapperTests {
    @Test func everyReviewerLandsInOneLine() {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .opened, approvedBy: ["kim"], assignees: ["sam"], reviewers: ["kim", "lee", "me"], changesRequestedBy: ["me"])

        let lines = PullRequestReviewMapper.lines(for: request, username: "me", words: .gitLab)

        #expect(lines.map(\.id) == ["approved", "changes", "waiting", "assignees"])
        #expect(lines.map(\.title) == ["Approved by", "Changes requested", "Waiting for", "Assigned to"])
        #expect(lines[0].tags.map(\.text) == ["kim"])
        #expect(lines[0].tags[0].tint == .green)
        #expect(lines[0].tags[0].hint == "kim approved this merge request")
        #expect(lines[1].tags.map(\.text) == ["you"])
        #expect(lines[1].tags[0].tint == .red)
        #expect(lines[1].tags[0].hint == "You asked for changes before this merge request can merge")
        #expect(lines[2].tags.map(\.text) == ["lee"])
        #expect(lines[2].tags[0].tint == .orange)
        #expect(lines[3].tags.map(\.text) == ["sam"])
    }

    @Test func aRequestedTeamWaitsAfterThePeople() {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .opened, reviewers: ["lee"], requestedTeams: ["example/ios"])

        let lines = PullRequestReviewMapper.lines(for: request, username: "me", words: .gitHub)

        #expect(lines.map(\.id) == ["waiting"])
        #expect(lines[0].tags.map(\.text) == ["lee", "example/ios"])
        #expect(lines[0].tags[1].systemImage == "person.3")
    }

    @Test func anOpenRequestWithoutReviewersSaysSo() {
        let lines = PullRequestReviewMapper.lines(for: PullRequestSummaryFixture.open, username: nil, words: .gitHub)

        #expect(lines.map(\.id) == ["waiting"])
        #expect(lines[0].title == "Reviewers")
        #expect(lines[0].tags.map(\.text) == ["none requested"])
        #expect(lines[0].tags[0].hint == "Nobody was asked to review this pull request yet")
    }

    @Test func anApprovedRequestWithoutOtherReviewersHasNoWaitingLine() {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .opened, approvedBy: ["kim"], reviewers: ["kim"])

        #expect(PullRequestReviewMapper.lines(for: request, username: nil, words: .gitLab).map(\.id) == ["approved"])
    }

    @Test func aMergedRequestListsNobodyAsWaiting() {
        let request = PullRequestSummaryFixture.request(iid: 1, source: "x", state: .merged, approvedBy: ["kim"], reviewers: ["kim", "lee"])

        #expect(PullRequestReviewMapper.lines(for: request, username: nil, words: .gitLab).map(\.id) == ["approved"])
        #expect(PullRequestReviewMapper.lines(for: PullRequestSummaryFixture.request(iid: 2, source: "y", state: .closed), username: nil, words: .gitLab).isEmpty)
    }
}
