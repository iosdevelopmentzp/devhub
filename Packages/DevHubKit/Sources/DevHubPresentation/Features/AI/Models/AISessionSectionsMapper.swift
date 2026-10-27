import Foundation
import DevHubDomain
import DevHubUI

enum AISessionSectionsMapper {
    static let favoritesTitle = "Favorites"

    static func sections(for sessions: [AISession], favorites: Set<AISession.ID>) -> [AISessionSection] {
        let pinned = sessions.filter { favorites.contains($0.id) }
        let others = sessions.filter { favorites.contains($0.id) == false }
        return favoriteSection(for: pinned) + daySections(for: others)
    }

    private static func favoriteSection(for sessions: [AISession]) -> [AISessionSection] {
        guard sessions.isEmpty == false else { return [] }
        let section = AISessionSection(
            title: favoritesTitle,
            systemImage: "star.fill",
            iconTint: .yellow,
            detail: CountText.count(sessions.count, "session"),
            rows: sessions.map { AISessionRowMapper.model(for: $0, isFavorite: true) }
        )
        return [section]
    }

    private static func daySections(for sessions: [AISession]) -> [AISessionSection] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.updatedAt) }
        return groups.keys.sorted(by: >).map { day in
            AISessionSection(
                title: dayTitle(day, calendar: calendar),
                systemImage: nil,
                iconTint: .secondary,
                detail: nil,
                rows: (groups[day] ?? []).map { AISessionRowMapper.model(for: $0, isFavorite: false) }
            )
        }
    }

    private static func dayTitle(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
