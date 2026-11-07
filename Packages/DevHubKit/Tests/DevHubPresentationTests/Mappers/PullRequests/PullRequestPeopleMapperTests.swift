import DevHubDomain
import DevHubUI
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct PullRequestPeopleMapperTests {
    private func context(username: String? = "alex", people: [String] = ["alex", "kim", "sam"], busy: Set<Int> = []) -> PullRequestRowContext {
        PullRequestRowContext(username: username, scope: .all, seenAt: nil, now: .now, isMainCheckoutClean: true, ticket: .standard, words: .gitLab, staleDays: 14, hiddenFiles: [], watchedIDs: [], people: people, busyPeopleIDs: busy)
    }

    private func request(author: String = "alex", state: PullRequestState = .opened, canMerge: Bool = false) -> PullRequestSummary {
        PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: state,
            author: author,
            assignees: ["alex"],
            reviewers: ["sam", "team-ios"],
            permissions: PullRequestPermissions(canMerge: canMerge, canApprove: true, canRevokeApproval: false, canSetAutoMerge: false)
        )
    }

    @Test func theCurrentPeopleComeFirstAndAreChecked() throws {
        let model = try #require(PullRequestPeopleMapper.model(summary: request(), context: context()))
        let reviewers = model.menus[0]

        #expect(reviewers.id == .reviewer)
        #expect(reviewers.title == "Reviewers 2")
        #expect(reviewers.options.map(\.id) == ["sam", "team-ios", "alex", "kim"])
        #expect(reviewers.options.map(\.isSelected) == [true, true, false, false])
        #expect(reviewers.options.first { $0.id == "alex" }?.title == "alex (you)")
        #expect(reviewers.hint.contains("merge request"))
    }

    @Test func assigneesHaveTheirOwnMenu() throws {
        let model = try #require(PullRequestPeopleMapper.model(summary: request(), context: context()))
        let assignees = model.menus[1]

        #expect(assignees.id == .assignee)
        #expect(assignees.title == "Assignees 1")
        #expect(assignees.options.filter(\.isSelected).map(\.id) == ["alex"])
    }

    @Test func theAuthorOrSomeoneWhoCanMergeCanEdit() {
        #expect(PullRequestPeopleMapper.model(summary: request(author: "sam"), context: context()) == nil)
        #expect(PullRequestPeopleMapper.model(summary: request(author: "sam", canMerge: true), context: context()) != nil)
        #expect(PullRequestPeopleMapper.model(summary: request(state: .merged), context: context()) == nil)
        #expect(PullRequestPeopleMapper.model(summary: request(), context: context(username: nil)) == nil)
    }

    @Test func busyAndEmptyStates() throws {
        let summary = PullRequestSummaryFixture.request(iid: 7, source: "x", state: .opened, author: "alex")

        let model = try #require(PullRequestPeopleMapper.model(summary: summary, context: context(people: [], busy: [7])))

        #expect(model.isBusy)
        #expect(model.menus.map(\.title) == ["Reviewers", "Assignees"])
        #expect(model.menus.allSatisfy { $0.emptyText == "No people found in this project" })
    }

    @Test func teamsFollowThePeopleInTheReviewerMenu() throws {
        var context = context()
        context.teams = ["example/ios", "example/qa"]
        let summary = PullRequestSummaryFixture.request(
            iid: 7,
            source: "x",
            state: .opened,
            author: "alex",
            reviewers: ["sam"],
            requestedTeams: ["example/qa"]
        )

        let model = try #require(PullRequestPeopleMapper.model(summary: summary, context: context))

        #expect(model.menus[0].title == "Reviewers 2")
        #expect(model.menus[0].teams.map(\.id) == ["example/qa", "example/ios"])
        #expect(model.menus[0].teams.map(\.isSelected) == [true, false])
        #expect(model.menus[0].teams.first?.title == "example/qa (team)")
        #expect(model.menus[1].teams.isEmpty)
    }
}
