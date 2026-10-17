import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct ClaudeSessionSectionsMapperTests {
    @Test func groupsByDayNewestFirst() throws {
        let calendar = Calendar.current
        let now = Date.now
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: now))
        let older = try #require(calendar.date(byAdding: .day, value: -10, to: now))
        let sessions = [
            session("older", updatedAt: older),
            session("today-1", updatedAt: now),
            session("yesterday", updatedAt: yesterday),
            session("today-2", updatedAt: now)
        ]

        let sections = ClaudeSessionSectionsMapper.sections(for: sessions)

        #expect(sections.map(\.title).prefix(2) == ["Today", "Yesterday"])
        #expect(sections.count == 3)
        #expect(sections[0].rows.map(\.id) == ["today-1", "today-2"])
        #expect(sections[1].rows.map(\.id) == ["yesterday"])
        #expect(sections[2].rows.map(\.id) == ["older"])
        #expect(sections[2].title == calendar.startOfDay(for: older).formatted(.dateTime.weekday(.wide).day().month(.wide)))
        #expect(sections[2].id == sections[2].title)
    }

    @Test func rowsUseTheRowMapper() {
        let sections = ClaudeSessionSectionsMapper.sections(for: [ClaudeSessionFixture.session])

        #expect(sections.first?.rows == [ClaudeSessionRowMapper.model(for: ClaudeSessionFixture.session)])
    }

    @Test func noSessionsGiveNoSections() {
        #expect(ClaudeSessionSectionsMapper.sections(for: []).isEmpty)
    }

    private func session(_ id: String, updatedAt: Date) -> ClaudeSession {
        ClaudeSession(
            id: id,
            title: "Session \(id)",
            lastPrompt: nil,
            cwd: ClaudeSessionFixture.session.cwd,
            gitBranch: nil,
            startedAt: nil,
            updatedAt: updatedAt,
            folderExists: true
        )
    }
}
