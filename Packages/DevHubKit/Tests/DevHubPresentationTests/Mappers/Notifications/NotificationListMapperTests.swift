import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct NotificationListMapperTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func groupsByDayNewestFirstWithTodayAndYesterday() throws {
        let today = event("A", minutesAgo: 5, kind: .build)
        let today2 = event("B", minutesAgo: 90, kind: nil)
        let yesterday = event("C", minutesAgo: 60 * 30, kind: .tests)
        let older = event("D", minutesAgo: 60 * 24 * 5, kind: .scripts)

        let sections = NotificationListMapper.sections(events: [today, today2, yesterday, older], filter: .all, query: "", words: .gitHub, now: now, calendar: calendar)

        #expect(sections.map(\.title).prefix(2) == ["Today", "Yesterday"])
        #expect(sections.count == 3)
        #expect(sections[0].rows.map(\.title) == ["A", "B"])
        #expect(sections[1].rows.map(\.title) == ["C"])
        #expect(sections[2].rows.map(\.title) == ["D"])
        #expect(sections[2].title.isEmpty == false)
    }

    @Test func aKindFilterKeepsOnlyThatKindAndOtherKeepsUntagged() {
        let events = [event("Build", minutesAgo: 1, kind: .build), event("Plain", minutesAgo: 2, kind: nil), event("Tests", minutesAgo: 3, kind: .tests)]

        let builds = NotificationListMapper.sections(events: events, filter: .kind(.build), query: "", words: .gitHub, now: now, calendar: calendar)
        let other = NotificationListMapper.sections(events: events, filter: .other, query: "", words: .gitHub, now: now, calendar: calendar)

        #expect(builds.flatMap(\.rows).map(\.title) == ["Build"])
        #expect(other.flatMap(\.rows).map(\.title) == ["Plain"])
    }

    @Test func theQueryMatchesTitleOrDetailWithoutCase() {
        let events = [event("Tests failed: feature/login", minutesAgo: 1, kind: .tests), event("Built App", minutesAgo: 2, kind: .build, detail: "Debug · login-worktree")]

        let sections = NotificationListMapper.sections(events: events, filter: .all, query: "  LOGIN ", words: .gitHub, now: now, calendar: calendar)

        #expect(sections.flatMap(\.rows).map(\.title) == ["Tests failed: feature/login", "Built App"])
        #expect(NotificationListMapper.sections(events: events, filter: .all, query: "nothing", words: .gitHub, now: now, calendar: calendar).isEmpty)
    }

    @Test func countTextShowsTheVisibleShareOnlyWhenFiltered() {
        #expect(NotificationListMapper.countText(visible: 3, total: 3) == "3 events")
        #expect(NotificationListMapper.countText(visible: 1, total: 1) == "1 event")
        #expect(NotificationListMapper.countText(visible: 2, total: 9) == "2 of 9 events")
    }

    private func event(_ title: String, minutesAgo: Int, kind: NotificationKind?, detail: String = "") -> ActivityEvent {
        ActivityEvent(id: UUID(), title: title, detail: detail, date: now.addingTimeInterval(-Double(minutesAgo) * 60), outcome: .info, kind: kind)
    }
}
