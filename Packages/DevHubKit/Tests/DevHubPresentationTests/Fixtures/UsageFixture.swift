import DevHubDomain
import Foundation

enum UsageFixture {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static let session = UsageLimit(id: "five_hour", title: "Session", usedFraction: 0.64, resetsAt: now.addingTimeInterval(2 * 3_600))

    static let week = UsageLimit(id: "seven_day", title: "Week", usedFraction: 0.22, resetsAt: now.addingTimeInterval(3 * 86_400))

    static let usage = ClaudeUsage(plan: "Max", limits: [session, week], updatedAt: now.addingTimeInterval(-60))
}
