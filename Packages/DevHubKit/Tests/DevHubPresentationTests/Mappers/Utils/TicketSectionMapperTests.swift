import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketSectionMapperTests {
    @Test func sectionsFollowTheCategoryOrderAndSkipEmptyOnes() {
        let issues = [
            issue("ABC-1", category: .toDo),
            issue("ABC-2", category: .inProgress),
            issue("ABC-3", category: .toDo),
            issue("ABC-4", category: .unknown),
        ]

        let sections = TicketSectionMapper.sections(for: issues, grouping: .status, starred: [])

        #expect(sections.map(\.id) == ["status:inProgress", "status:toDo", "status:unknown"])
        #expect(sections.map(\.title) == ["In progress", "To do", "Other"])
        #expect(sections[1].issues.map(\.key) == ["ABC-1", "ABC-3"])
    }

    @Test func noIssuesMeansNoSections() {
        for grouping in TicketGrouping.allCases {
            #expect(TicketSectionMapper.sections(for: [], grouping: grouping, starred: ["ABC-1"]).isEmpty)
        }
        #expect(TicketSectionMapper.title(for: .done) == "Done")
    }

    @Test func starredTicketsComeFirstAndLeaveTheirGroups() {
        let issues = [
            issue("ABC-1", category: .toDo),
            issue("ABC-2", category: .inProgress),
            issue("ABC-3", category: .toDo),
        ]

        let sections = TicketSectionMapper.sections(for: issues, grouping: .status, starred: ["ABC-3", "ABC-9"])

        #expect(sections.map(\.id) == ["starred", "status:inProgress", "status:toDo"])
        #expect(sections[0].title == "Starred")
        #expect(sections[0].issues.map(\.key) == ["ABC-3"])
        #expect(sections[2].issues.map(\.key) == ["ABC-1"])
    }

    @Test func aStarThatMatchesNothingAddsNoSection() {
        let sections = TicketSectionMapper.sections(for: [issue("ABC-1")], grouping: .status, starred: ["ABC-9"])

        #expect(sections.map(\.id) == ["status:toDo"])
    }

    @Test func typesAreOrderedByCountThenByName() {
        let issues = [
            issue("ABC-1", type: "Task"),
            issue("ABC-2", type: "Bug"),
            issue("ABC-3", type: "Bug"),
            issue("ABC-4", type: "Story"),
            issue("ABC-5", type: ""),
        ]

        let sections = TicketSectionMapper.sections(for: issues, grouping: .type, starred: [])

        #expect(sections.map(\.title) == ["Bug", "Other", "Story", "Task"])
        #expect(sections[0].issues.map(\.key) == ["ABC-2", "ABC-3"])
        #expect(sections[0].id == "type:Bug")
    }

    @Test func assigneesAreSortedWithUnassignedLast() {
        let issues = [
            issue("ABC-1", assignee: nil),
            issue("ABC-2", assignee: "Sam"),
            issue("ABC-3", assignee: "Alex"),
        ]

        #expect(TicketSectionMapper.sections(for: issues, grouping: .assignee, starred: []).map(\.title) == ["Alex", "Sam", "Unassigned"])
    }

    @Test func prioritiesFollowTheirRankWithUnknownNamesAndNoPriorityLast() {
        let issues = [
            issue("ABC-1", priority: "Low"),
            issue("ABC-2", priority: nil),
            issue("ABC-3", priority: "Highest"),
            issue("ABC-4", priority: "Urgent-ish"),
            issue("ABC-5", priority: "Medium"),
        ]

        #expect(TicketSectionMapper.sections(for: issues, grouping: .priority, starred: []).map(\.title) == ["Highest", "Medium", "Low", "Urgent-ish", "No priority"])
        #expect(TicketSectionMapper.priorityRank("Blocker") == 0)
        #expect(TicketSectionMapper.priorityRank("major") == 1)
        #expect(TicketSectionMapper.priorityRank("Trivial") == 4)
    }

    private func issue(_ key: String, category: IssueStatusCategory = .toDo, type: String = "Task", assignee: String? = nil, priority: String? = nil) -> TrackerIssue {
        TrackerIssue(key: key, summary: key, status: "", statusCategory: category, type: type, priority: priority, assignee: assignee, url: nil, updatedAt: nil)
    }
}
