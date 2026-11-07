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

        let sections = TicketSectionMapper.sections(for: issues)

        #expect(sections.map(\.id) == [.inProgress, .toDo, .unknown])
        #expect(sections.map(\.title) == ["In progress", "To do", "Other"])
        #expect(sections[1].issues.map(\.key) == ["ABC-1", "ABC-3"])
    }

    @Test func noIssuesMeansNoSections() {
        #expect(TicketSectionMapper.sections(for: []).isEmpty)
        #expect(TicketSectionMapper.title(for: .done) == "Done")
    }

    private func issue(_ key: String, category: IssueStatusCategory) -> TrackerIssue {
        TrackerIssue(key: key, summary: key, status: "", statusCategory: category, type: "Task", priority: nil, assignee: nil, url: nil, updatedAt: nil)
    }
}
