import Foundation

nonisolated enum CopilotTokenParser {
    private static let tokenFields = ["oauth_token", "access_token", "token", "accessToken"]

    static func parse(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        guard trimmed.hasPrefix("{") else { return trimmed }
        guard let data = trimmed.data(using: .utf8), let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        return tokenFields.lazy.compactMap { object[$0] as? String }.first { $0.isEmpty == false }
    }
}

nonisolated enum CopilotUsageParser {
    static func parse(_ data: Data) -> ProviderUsage? {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        let plan = (object["copilot_plan"] as? String).flatMap { $0.isEmpty ? nil : $0.capitalized }
        let resetDate = ISODateParser.parse(object["quota_reset_date"] as? String)
        let premium = (object["quota_snapshots"] as? [String: Any])?["premium_interactions"] as? [String: Any]
        guard let premium, (premium["unlimited"] as? Bool) != true, let meter = meter(from: premium, resetDate: resetDate) else {
            return ProviderUsage(meters: [], plan: plan, note: plan == nil ? nil : "No premium request limit")
        }
        return ProviderUsage(meters: [meter], plan: plan, note: nil)
    }

    private static func meter(from premium: [String: Any], resetDate: Date?) -> UsageMeter? {
        let entitlement = UsageNumber.double(premium["entitlement"])
        let remaining = UsageNumber.double(premium["remaining"])
        let percentRemaining = UsageNumber.double(premium["percent_remaining"])
        let used: Double?
        let percent: Double
        if let entitlement, entitlement > 0, let remaining {
            used = entitlement - remaining
            percent = (entitlement - remaining) / entitlement * 100
        } else if let percentRemaining {
            used = nil
            percent = 100 - percentRemaining
        } else {
            return nil
        }
        var detail: String?
        if let used, let entitlement {
            detail = "\(Int(used.rounded())) of \(Int(entitlement.rounded())) used"
        }
        return UsageMeter(id: "premium", title: "Premium requests", percent: percent, resetsAt: resetDate, detail: detail)
    }
}
