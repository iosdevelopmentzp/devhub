import Foundation
import DevHubDomain

extension MockData {
    package static let usage = ClaudeUsage(
        plan: "Team",
        limits: [
            UsageLimit(id: "session", title: "Session", usedFraction: 0.35, resetsAt: now.addingTimeInterval(3 * 3600 + 19 * 60)),
            UsageLimit(id: "week-all", title: "Week · all", usedFraction: 0.18, resetsAt: nextSundayMorning),
            UsageLimit(id: "week-fable", title: "Week · Fable", usedFraction: 0.32, resetsAt: nextSundayMorning)
        ],
        updatedAt: now
    )

    package static let copilotUsage = CopilotUsage(
        plan: "Business",
        limits: [UsageLimit(id: "premium", title: "Premium", usedFraction: 0.42, resetsAt: now.addingTimeInterval(12 * 86400))],
        updatedAt: now
    )

    private static let nextSundayMorning: Date = {
        let components = DateComponents(hour: 9, minute: 0, weekday: 1)
        return Calendar.current.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now.addingTimeInterval(5 * 86400)
    }()
}
