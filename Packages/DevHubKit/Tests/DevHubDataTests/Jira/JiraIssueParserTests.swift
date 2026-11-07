import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct JiraIssueParserTests {
    @Test func parsesASearchAnswer() throws {
        let issues = try JiraIssueParser.issues(from: Data(JiraFixture.search.utf8))

        #expect(issues.map(\.key) == ["ABC-123", "ABC-124"])
        let first = try #require(issues.first)
        #expect(first.summary == "Login button stays disabled after a failed request")
        #expect(first.status == "In Progress")
        #expect(first.statusCategory == .inProgress)
        #expect(first.type == "Bug")
        #expect(first.priority == "High")
        #expect(first.assignee == "Alex")
        #expect(first.url == URL(string: "https://jira.example.com/browse/ABC-123"))
        #expect(first.updatedAt == JiraDateParser.date(from: "2026-11-06T13:11:45.043+0000"))
        #expect(first.updatedAt != nil)
    }

    @Test func missingFieldsStayEmpty() throws {
        let issues = try JiraIssueParser.issues(from: Data(JiraFixture.search.utf8))

        let second = try #require(issues.last)
        #expect(second.priority == nil)
        #expect(second.assignee == nil)
        #expect(second.statusCategory == .toDo)
        #expect(second.type == "Story")
    }

    @Test func parsesOneIssue() throws {
        let issue = try JiraIssueParser.issue(from: Data(JiraFixture.issue.utf8))

        #expect(issue.key == "ABC-130")
        #expect(issue.statusCategory == .done)
        #expect(issue.priority == "Highest")
        #expect(issue.assignee == "Sam")
        #expect(issue.updatedAt != nil)
    }

    @Test func aPlainListAndAnUnknownCategoryAreAccepted() throws {
        let issues = try JiraIssueParser.issues(from: Data(JiraFixture.list.utf8))

        #expect(issues.map(\.key) == ["ABC-200"])
        #expect(issues.first?.statusCategory == .unknown)
        #expect(issues.first?.url == nil)
        #expect(issues.first?.type == "")
    }

    @Test func brokenJSONIsUnreadable() {
        #expect(throws: TrackerError.self) {
            try JiraIssueParser.issues(from: Data("not json".utf8))
        }
        #expect(throws: TrackerError.self) {
            try JiraIssueParser.issue(from: Data("{}".utf8))
        }
    }

    @Test func theBrowseLinkComesFromTheAPILink() {
        #expect(JiraIssueParser.browseURL(apiURL: "https://jira.example.com/rest/api/2/issue/1", key: "ABC-1") == URL(string: "https://jira.example.com/browse/ABC-1"))
        #expect(JiraIssueParser.browseURL(apiURL: "https://jira.example.com/jira/rest/api/3/issue/1", key: "ABC-1") == URL(string: "https://jira.example.com/jira/browse/ABC-1"))
        #expect(JiraIssueParser.browseURL(apiURL: nil, key: "ABC-1") == nil)
        #expect(JiraIssueParser.browseURL(apiURL: "no-rest-here", key: "ABC-1") == nil)
    }

    @Test func statusCategoriesMapToTheKnownOnes() {
        #expect(JiraIssueParser.category(forKey: "new") == .toDo)
        #expect(JiraIssueParser.category(forKey: "indeterminate") == .inProgress)
        #expect(JiraIssueParser.category(forKey: "done") == .done)
        #expect(JiraIssueParser.category(forKey: "undefined") == .unknown)
        #expect(JiraIssueParser.category(forKey: nil) == .unknown)
    }
}
