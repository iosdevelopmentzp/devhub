import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestPeopleTextTests {
    @Test func eachRoleAndDirectionHasItsTitle() {
        #expect(PullRequestPeopleText.title(login: "sam", role: .reviewer, adds: true, reference: "#12") == "Request review from sam on #12")
        #expect(PullRequestPeopleText.title(login: "sam", role: .reviewer, adds: false, reference: "#12") == "Remove sam as reviewer of #12")
        #expect(PullRequestPeopleText.title(login: "sam", role: .assignee, adds: true, reference: "!12") == "Assign !12 to sam")
        #expect(PullRequestPeopleText.title(login: "sam", role: .assignee, adds: false, reference: "!12") == "Unassign sam from !12")
    }
}
