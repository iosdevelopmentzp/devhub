import Foundation

nonisolated enum ClaudeUsageParser {
    private static let mainKeys: Set<String> = ["five_hour", "seven_day"]
    private static let ignoredKeys: Set<String> = ["seven_day_oauth_apps"]

    static func parse(_ data: Data) -> [UsageMeter] {
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [] }
        var meters: [UsageMeter] = []
        for key in orderedKeys(object.keys) {
            if object[key] is NSNull, mainKeys.contains(key) {
                meters.append(UsageMeter(id: key, title: title(for: key), percent: 0, resetsAt: nil, detail: "No active window"))
                continue
            }
            guard let entry = object[key] as? [String: Any], let percent = UsageNumber.double(entry["utilization"]) else { continue }
            meters.append(UsageMeter(
                id: key,
                title: title(for: key),
                percent: percent,
                resetsAt: ISODateParser.parse(entry["resets_at"] as? String),
                detail: nil
            ))
        }
        return meters
    }

    private static func orderedKeys(_ keys: Dictionary<String, Any>.Keys) -> [String] {
        let known = ["five_hour", "seven_day"].filter { keys.contains($0) }
        let models = keys
            .filter { $0.hasPrefix("seven_day_") && ignoredKeys.contains($0) == false }
            .sorted()
        return known + models
    }

    private static func title(for key: String) -> String {
        switch key {
        case "five_hour": return "Session"
        case "seven_day": return "Week · all"
        default:
            let model = key.dropFirst("seven_day_".count).replacingOccurrences(of: "_", with: " ")
            return "Week · \(model.capitalized)"
        }
    }
}
