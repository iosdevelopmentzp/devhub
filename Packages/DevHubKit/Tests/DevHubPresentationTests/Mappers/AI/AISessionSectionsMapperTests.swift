import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AISessionSectionsMapperTests {
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

        let sections = AISessionSectionsMapper.sections(for: sessions)

        #expect(sections.map(\.title).prefix(2) == ["Today", "Yesterday"])
        #expect(sections.count == 3)
        #expect(sections[0].rows.map(\.id) == ["today-1", "today-2"])
        #expect(sections[1].rows.map(\.id) == ["yesterday"])
        #expect(sections[2].rows.map(\.id) == ["older"])
        #expect(sections[2].title == calendar.startOfDay(for: older).formatted(.dateTime.weekday(.wide).day().month(.wide)))
        #expect(sections[2].id == sections[2].title)
    }

    @Test func rowsUseTheRowMapper() {
        let sections = AISessionSectionsMapper.sections(for: [AISessionFixture.session])

        #expect(sections.first?.rows == [AISessionRowMapper.model(for: AISessionFixture.session)])
    }

    @Test func noSessionsGiveNoSections() {
        #expect(AISessionSectionsMapper.sections(for: []).isEmpty)
    }

    private func session(_ id: String, updatedAt: Date) -> AISession {
        AISession(
            id: id,
            provider: .claude,
            title: "Session \(id)",
            lastPrompt: nil,
            cwd: AISessionFixture.session.cwd,
            gitBranch: nil,
            startedAt: nil,
            updatedAt: updatedAt,
            folderExists: true
        )
    }
}
