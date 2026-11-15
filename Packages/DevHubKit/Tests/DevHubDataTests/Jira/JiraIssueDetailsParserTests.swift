import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct JiraIssueDetailsParserTests {
    @Test func aServerAnswerHasPlainTextFields() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(JiraFixture.serverDetails.utf8))

        #expect(details.key == "ABC-123")
        #expect(details.description == "Steps:\n1. Open the login screen.\n2. Tap Log In.")
        #expect(details.reporter == "Sam")
        #expect(details.createdAt == JiraDateParser.date(from: "2026-11-01T09:00:00.000+0000"))
        #expect(details.labels == ["ios", "login"])
        #expect(details.components == ["Auth"])
        #expect(details.parent == TrackerIssueLink(key: "ABC-100", summary: "Login flow rework", status: "In Progress", statusCategory: .inProgress))
        #expect(details.subtasks == [TrackerIssueLink(key: "ABC-131", summary: "Add a unit test", status: "To Do", statusCategory: .toDo)])
        #expect(details.comments == [TrackerComment(id: "5001", author: "Alex", body: "Found it.", createdAt: JiraDateParser.date(from: "2026-11-02T10:00:00.000+0000"))])
    }

    @Test func aCloudAnswerTurnsTheDocumentIntoText() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(JiraFixture.cloudDetails.utf8))

        #expect(details.description == "The button stays disabled.\nAfter a restart it works.\n\nWhat to check:\n\n• the retry\n• the timeout\n\nlet value = 1\n\nSee @Sam and https://example.com/spec")
        #expect(details.comments.map(\.body) == ["Fixed on main 👍"])
        #expect(details.comments.first?.author == "Sam")
        #expect(details.reporter == nil)
        #expect(details.labels.isEmpty)
        #expect(details.parent == nil)
        #expect(details.subtasks.isEmpty)
    }

    @Test func aMissingDescriptionIsEmptyAndBrokenJSONIsUnreadable() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(#"{"key":"ABC-1","fields":{"description":null}}"#.utf8))

        #expect(details.description == "")
        #expect(details.comments.isEmpty)
        #expect(throws: TrackerError.self) { try JiraIssueDetailsParser.details(from: Data("not json".utf8)) }
    }
}
