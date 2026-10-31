import Foundation
import DevHubDomain
import DevHubUI

enum NotificationListMapper {

    static func sections(events: [ActivityEvent], filter: NotificationFilter, query: String, words: CodeHostWords, now: Date, calendar: Calendar) -> [NotificationSectionModel] {
        let visible = events.filter { filter.includes($0) && matches($0, query: query) }
        var sections: [NotificationSectionModel] = []
        for event in visible {
            let day = calendar.startOfDay(for: event.date)
            let row = ActivityRowMapper.model(for: event, words: words)
            if sections.last?.id == day {
                sections[sections.count - 1].rows.append(row)
            } else {
                sections.append(NotificationSectionModel(id: day, title: DayLabel.text(for: day, now: now, calendar: calendar), rows: [row]))
            }
        }
        return sections
    }

    static func countText(visible: Int, total: Int) -> String {
        countText(visible: visible, total: total, noun: "event")
    }

    static func countText(visible: Int, total: Int, noun: String) -> String {
        guard visible != total else { return CountText.count(total, noun, noun + "s") }
        return "\(visible) of \(CountText.count(total, noun, noun + "s"))"
    }

    private static func matches(_ event: ActivityEvent, query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { return true }
        return event.title.localizedCaseInsensitiveContains(trimmed) || event.detail.localizedCaseInsensitiveContains(trimmed)
    }
}
