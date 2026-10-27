import Foundation
import DevHubDomain

enum ClaudeUsageParser {
    private static let fixedLimits: [(key: String, title: String)] = [
        ("five_hour", "Session"),
        ("seven_day", "Week · all")
    ]
    private static let ignoredKeys: Set<String> = ["seven_day_oauth_apps"]
    private static let modelPrefix = "seven_day_"
    private static let scopedKind = "weekly_scoped"

    static func parse(_ data: Data, plan: String?, now: Date) throws -> ClaudeUsage {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeUsageError.malformedResponse
        }

        var limits: [UsageLimit] = []
        for (key, title) in fixedLimits {
            if let limit = limit(from: object[key], id: key, title: title) {
                limits.append(limit)
            }
        }

        let modelKeys = object.keys
            .filter { $0.hasPrefix(modelPrefix) && ignoredKeys.contains($0) == false }
            .sorted()
        for key in modelKeys {
            let name = key.dropFirst(modelPrefix.count).replacingOccurrences(of: "_", with: " ").capitalized
            if let limit = limit(from: object[key], id: key, title: "Week · \(name)") {
                limits.append(limit)
            }
        }

        for limit in scopedLimits(from: object["limits"]) where limits.contains(where: { $0.id == limit.id }) == false {
            limits.append(limit)
        }

        guard limits.isEmpty == false else { throw ClaudeUsageError.malformedResponse }
        return ClaudeUsage(plan: plan?.capitalized ?? "Claude", limits: limits, updatedAt: now)
    }

    private static func scopedLimits(from value: Any?) -> [UsageLimit] {
        guard let entries = value as? [[String: Any]] else { return [] }
        return entries.compactMap { entry in
            guard entry["kind"] as? String == scopedKind,
                  let name = scopeName(from: entry["scope"]),
                  let percent = entry["percent"] as? Double
            else { return nil }
            let id = modelPrefix + name.lowercased().replacingOccurrences(of: " ", with: "_")
            let resetsAt = (entry["resets_at"] as? String).flatMap { ISO8601.date(from: $0) }
            return UsageLimit(id: id, title: "Week · \(name)", usedFraction: percent / 100, resetsAt: resetsAt)
        }
    }

    private static func scopeName(from value: Any?) -> String? {
        guard let scope = value as? [String: Any] else { return nil }
        let model = scope["model"] as? [String: Any]
        let surface = scope["surface"] as? [String: Any]
        let name = model?["display_name"] as? String ?? surface?["display_name"] as? String ?? scope["surface"] as? String
        guard let name, name.isEmpty == false else { return nil }
        return name
    }

    private static func limit(from value: Any?, id: String, title: String) -> UsageLimit? {
        guard let dictionary = value as? [String: Any], let utilization = dictionary["utilization"] as? Double else { return nil }
        let resetsAt = (dictionary["resets_at"] as? String).flatMap { ISO8601.date(from: $0) }
        return UsageLimit(id: id, title: title, usedFraction: utilization / 100, resetsAt: resetsAt)
    }
}
