import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketRowMapperTests {
    @Test func aBugInToDoCanStartAndMove() {
        let model = TicketRowMapper.model(for: issue(type: "Bug", status: "To Do", category: .toDo, priority: "High"), settings: .standard, isBusy: false)

        #expect(model.id == "ABC-123")
        #expect(model.typeIcon == "ladybug")
        #expect(model.typeTint == .red)
        #expect(model.typeHint == "Bug")
        #expect(model.statusTag == TagModel("To Do", tint: .secondary, hint: "Status in the tracker"))
        #expect(model.priorityTag == TagModel("High", tint: .orange, systemImage: "flag", hint: "Priority"))
        #expect(model.assignee == "Alex")
        #expect(model.updatedText?.hasPrefix("updated ") == true)
        #expect(model.url == URL(string: "https://jira.example.com/browse/ABC-123"))
        #expect(model.branchName == "feature/ABC-123-login-button-stays-disabled")
        #expect(model.startTitle == "Move to In Progress")
        #expect(model.canStart)
        #expect(model.moveTargets == ["In Progress", "In Review", "Done"])
        #expect(model.isBusy == false)
    }

    @Test func aTicketAlreadyInTheStartStatusCannotStart() {
        let model = TicketRowMapper.model(for: issue(type: "Story", status: "in progress", category: .inProgress, priority: nil), settings: .standard, isBusy: true)

        #expect(model.canStart == false)
        #expect(model.moveTargets == ["To Do", "In Review", "Done"])
        #expect(model.statusTag.tint == .blue)
        #expect(model.priorityTag == nil)
        #expect(model.isBusy)
        #expect(model.typeIcon == "book.closed")
        #expect(model.typeTint == .green)
    }

    @Test func aDoneTicketCannotStart() {
        let model = TicketRowMapper.model(for: issue(type: "Task", status: "Done", category: .done, priority: "Lowest"), settings: .standard, isBusy: false)

        #expect(model.canStart == false)
        #expect(model.statusTag.tint == .green)
        #expect(model.priorityTag?.tint == .gray)
        #expect(model.typeIcon == "checkmark.square")
    }

    @Test func iconsAndTintsByType() {
        #expect(TicketRowMapper.typeIcon("Epic") == "flag.2.crossed")
        #expect(TicketRowMapper.typeTint("Epic") == .purple)
        #expect(TicketRowMapper.typeIcon("Sub-task") == "checkmark.square")
        #expect(TicketRowMapper.typeIcon("Improvement") == "doc.text")
        #expect(TicketRowMapper.typeTint("Improvement") == .secondary)
    }

    @Test func anEmptyTypeIsCalledTicket() {
        let empty = TrackerIssue(key: "ABC-1", summary: "", status: "", statusCategory: .unknown, type: "", priority: nil, assignee: nil, url: nil, updatedAt: nil)

        #expect(TicketRowMapper.model(for: empty, settings: .standard, isBusy: false).typeHint == "Ticket")
    }

    @Test func priorityTints() {
        #expect(TicketRowMapper.priorityTint("Highest") == .red)
        #expect(TicketRowMapper.priorityTint("Blocker") == .red)
        #expect(TicketRowMapper.priorityTint("High") == .orange)
        #expect(TicketRowMapper.priorityTint("Medium") == .secondary)
        #expect(TicketRowMapper.priorityTint("Low") == .gray)
    }

    @Test func statusTints() {
        #expect(TicketRowMapper.statusTint(.toDo) == .secondary)
        #expect(TicketRowMapper.statusTint(.inProgress) == .blue)
        #expect(TicketRowMapper.statusTint(.done) == .green)
        #expect(TicketRowMapper.statusTint(.unknown) == .gray)
    }

    private func issue(type: String, status: String, category: IssueStatusCategory, priority: String?) -> TrackerIssue {
        TrackerIssue(
            key: "ABC-123",
            summary: "Login button stays disabled",
            status: status,
            statusCategory: category,
            type: type,
            priority: priority,
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-123"),
            updatedAt: Date(timeIntervalSinceNow: -3_600)
        )
    }
}
