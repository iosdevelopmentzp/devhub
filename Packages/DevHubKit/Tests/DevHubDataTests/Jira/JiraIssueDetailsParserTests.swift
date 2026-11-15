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

    @Test func aServerAnswerHasVersionsLinksFilesTimeAndWatchers() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(JiraFixture.serverDetails.utf8))

        #expect(details.fixVersions == ["2.4.0"])
        #expect(details.dueDate != nil)
        #expect(details.dueDate == JiraDateParser.day(from: "2026-11-20", calendar: .current))
        #expect(details.resolution == "Fixed")
        #expect(details.links == [
            TrackerIssueRelation(
                relation: "blocks",
                issue: TrackerIssueLink(key: "ABC-140", summary: "Release 2.4.0 checklist", status: "To Do", statusCategory: .toDo)
            ),
            TrackerIssueRelation(
                relation: "is blocked by",
                issue: TrackerIssueLink(key: "ABC-99", summary: "Session refresh endpoint", status: "Done", statusCategory: .done)
            ),
        ])
        #expect(details.attachments == ["login-screen.png", "console.log"])
        #expect(details.originalEstimateSeconds == 14_400)
        #expect(details.timeSpentSeconds == 5_400)
        #expect(details.remainingEstimateSeconds == 9_000)
        #expect(details.watchers == 3)
        #expect(details.isWatching == true)
    }

    @Test func anAnswerWithoutTheNewMembersLeavesThemEmpty() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(JiraFixture.cloudDetails.utf8))

        #expect(details.fixVersions.isEmpty)
        #expect(details.dueDate == nil)
        #expect(details.resolution == nil)
        #expect(details.links.isEmpty)
        #expect(details.attachments.isEmpty)
        #expect(details.originalEstimateSeconds == nil)
        #expect(details.timeSpentSeconds == nil)
        #expect(details.remainingEstimateSeconds == nil)
        #expect(details.watchers == nil)
        #expect(details.isWatching == nil)
    }

    @Test func aLinkWithoutADirectionTextUsesTheTypeNameThenNothing() throws {
        let json = #"""
        {
          "key": "ABC-1",
          "fields": {
            "issuelinks": [
              { "type": { "name": "Relates" }, "outwardIssue": { "key": "ABC-2" } },
              { "type": { "name": "Relates" }, "inwardIssue": { "key": "ABC-3" } },
              { "outwardIssue": { "key": "ABC-4" } },
              { "type": { "name": "Relates" } },
              {}
            ]
          }
        }
        """#

        let details = try JiraIssueDetailsParser.details(from: Data(json.utf8))

        #expect(details.links == [
            TrackerIssueRelation(
                relation: "Relates",
                issue: TrackerIssueLink(key: "ABC-2", summary: "", status: "", statusCategory: .unknown)
            ),
            TrackerIssueRelation(
                relation: "Relates",
                issue: TrackerIssueLink(key: "ABC-3", summary: "", status: "", statusCategory: .unknown)
            ),
            TrackerIssueRelation(
                relation: "",
                issue: TrackerIssueLink(key: "ABC-4", summary: "", status: "", statusCategory: .unknown)
            ),
        ])
    }

    @Test func aBrokenDueDateAndEmptyNamesAreLeftOut() throws {
        let json = #"""
        {
          "key": "ABC-1",
          "fields": {
            "duedate": "2026-11-20T10:00:00.000+0000",
            "resolution": null,
            "fixVersions": [{ "id": "20" }, { "name": "2.4.0" }],
            "attachment": [{ "id": "1" }, { "filename": "console.log" }],
            "timetracking": {},
            "watches": { "watchCount": 0 }
          }
        }
        """#

        let details = try JiraIssueDetailsParser.details(from: Data(json.utf8))

        #expect(details.dueDate == nil)
        #expect(details.resolution == nil)
        #expect(details.fixVersions == ["2.4.0"])
        #expect(details.attachments == ["console.log"])
        #expect(details.originalEstimateSeconds == nil)
        #expect(details.watchers == 0)
        #expect(details.isWatching == nil)
    }

    @Test func aMissingDescriptionIsEmptyAndBrokenJSONIsUnreadable() throws {
        let details = try JiraIssueDetailsParser.details(from: Data(#"{"key":"ABC-1","fields":{"description":null}}"#.utf8))

        #expect(details.description == "")
        #expect(details.comments.isEmpty)
        #expect(throws: TrackerError.self) { try JiraIssueDetailsParser.details(from: Data("not json".utf8)) }
    }
}
