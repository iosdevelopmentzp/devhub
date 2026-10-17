import Foundation

nonisolated struct AIDayGroup: Identifiable, Hashable, Sendable {
    let day: Date
    let title: String
    let sessions: [AISession]

    var id: Date { day }

    static func group(_ sessions: [AISession], now: Date = Date(), calendar: Calendar = .current) -> [AIDayGroup] {
        let buckets = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        return buckets.keys.sorted(by: >).map { day in
            let ordered = (buckets[day] ?? []).sorted { left, right in
                if left.provider != right.provider {
                    return left.provider.sortOrder < right.provider.sortOrder
                }
                return left.date > right.date
            }
            return AIDayGroup(day: day, title: title(for: day, now: now, calendar: calendar), sessions: ordered)
        }
    }

    private static func title(for day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return "Today"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return day.formatted(date: .complete, time: .omitted)
    }
}
