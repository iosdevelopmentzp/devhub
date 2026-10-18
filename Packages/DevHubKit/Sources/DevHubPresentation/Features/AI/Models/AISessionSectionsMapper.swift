import Foundation
import DevHubDomain
import DevHubUI

enum AISessionSectionsMapper {

    static func sections(for sessions: [AISession]) -> [AISessionSection] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.updatedAt) }
        return groups.keys.sorted(by: >).map { day in
            AISessionSection(
                title: dayTitle(day, calendar: calendar),
                rows: (groups[day] ?? []).map { AISessionRowMapper.model(for: $0) }
            )
        }
    }

    private static func dayTitle(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
