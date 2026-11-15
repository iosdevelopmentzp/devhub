import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketRowMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aBugInToDoCanStartAndMove() {
        let model = model(for: issue(type: "Bug", status: "To Do", category: .toDo, priority: "High"))

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
        #expect(model.canUnassign)
        #expect(model.dueTag == nil)
        #expect(model.labelTags.isEmpty)
    }

    @Test func aTicketAlreadyInTheStartStatusCannotStart() {
        let model = TicketRowMapper.model(for: issue(type: "Story", status: "in progress", category: .inProgress, priority: nil), settings: .standard, isBusy: true, isExpanded: false, isStarred: false, canAssignToMe: false, canWatch: false, now: now)

        #expect(model.canStart == false)
        #expect(model.moveTargets == ["To Do", "In Review", "Done"])
        #expect(model.statusTag.tint == .blue)
        #expect(model.priorityTag == nil)
        #expect(model.isBusy)
        #expect(model.typeIcon == "book.closed")
        #expect(model.typeTint == .green)
    }

    @Test func aDoneTicketCannotStart() {
        let model = model(for: issue(type: "Task", status: "Done", category: .done, priority: "Lowest"))

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

        let model = model(for: empty)

        #expect(model.typeHint == "Ticket")
        #expect(model.keyAndSummary == "ABC-1")
        #expect(model.canUnassign == false)
    }

    @Test func theRowCarriesTheExpansionTheStarAndTheChoices() {
        let model = TicketRowMapper.model(for: issue(type: "Bug", status: "To Do", category: .toDo, priority: nil), settings: .standard, isBusy: false, isExpanded: true, isStarred: true, canAssignToMe: true, canWatch: true, now: now)

        #expect(model.isExpanded)
        #expect(model.isStarred)
        #expect(model.starTitle == "Unstar")
        #expect(model.starHint == "Remove the star")
        #expect(model.canAssignToMe)
        #expect(model.canWatch)
        #expect(model.keyAndSummary == "ABC-123 Login button stays disabled")
    }

    @Test func atMostTwoLabelsShowAndTheRestIsCounted() {
        let tags = TicketRowMapper.labelTags(["ios", "login", "auth", "crash"])

        #expect(tags.map(\.text) == ["ios", "login", "+2"])
        #expect(tags[0].systemImage == "tag")
        #expect(tags[2].hint == "auth, crash")
        #expect(TicketRowMapper.labelTags(["ios"]).map(\.text) == ["ios"])
    }

    @Test func theDueTagIsRedWhenOverdueOrangeTodayAndPlainOtherwise() throws {
        let overdue = try #require(TicketRowMapper.dueTag(for: now.addingTimeInterval(-2 * 86_400), isDone: false, now: now))
        let today = try #require(TicketRowMapper.dueTag(for: now, isDone: false, now: now))
        let later = try #require(TicketRowMapper.dueTag(for: now.addingTimeInterval(3 * 86_400), isDone: false, now: now))
        let done = try #require(TicketRowMapper.dueTag(for: now.addingTimeInterval(-2 * 86_400), isDone: true, now: now))

        #expect(overdue.tint == .red)
        #expect(overdue.hint == "Overdue")
        #expect(overdue.text.hasPrefix("Due "))
        #expect(today.tint == .orange)
        #expect(today.text == "Due Today")
        #expect(later.tint == .secondary)
        #expect(done.tint == .secondary)
        #expect(TicketRowMapper.dueTag(for: nil, isDone: false, now: now) == nil)
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

    private func model(for issue: TrackerIssue) -> TicketRowModel {
        TicketRowMapper.model(for: issue, settings: .standard, isBusy: false, isExpanded: false, isStarred: false, canAssignToMe: false, canWatch: false, now: now)
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
