import Foundation
import DevHubDomain

enum CopilotUsageParser {
    private static let dayOnly = Date.ISO8601FormatStyle().year().month().day()

    static func parse(_ data: Data, now: Date) throws -> CopilotUsage {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw CopilotUsageError.malformedResponse
        }
        let plan = (object["copilot_plan"] as? String).flatMap { $0.isEmpty ? nil : $0.capitalized }
        let premium = (object["quota_snapshots"] as? [String: Any])?["premium_interactions"] as? [String: Any]
        guard let premium else {
            guard plan != nil else { throw CopilotUsageError.malformedResponse }
            return CopilotUsage(plan: plan, limits: [], updatedAt: now)
        }
        guard (premium["unlimited"] as? Bool) != true else {
            return CopilotUsage(plan: plan, limits: [], updatedAt: now)
        }
        guard let fraction = usedFraction(premium) else { throw CopilotUsageError.malformedResponse }
        let limit = UsageLimit(id: "premium", title: "Premium", usedFraction: fraction, resetsAt: date(object["quota_reset_date"] as? String))
        return CopilotUsage(plan: plan, limits: [limit], updatedAt: now)
    }

    private static func usedFraction(_ premium: [String: Any]) -> Double? {
        if let entitlement = number(premium["entitlement"]), entitlement > 0, let remaining = number(premium["remaining"]) {
            return min(max((entitlement - remaining) / entitlement, 0), 1)
        }
        guard let percentRemaining = number(premium["percent_remaining"]) else { return nil }
        return min(max((100 - percentRemaining) / 100, 0), 1)
    }

    private static func number(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber: number.doubleValue
        case let text as String: Double(text)
        default: nil
        }
    }

    private static func date(_ text: String?) -> Date? {
        guard let text else { return nil }
        return ISO8601.date(from: text) ?? (try? dayOnly.parse(text))
    }
}
