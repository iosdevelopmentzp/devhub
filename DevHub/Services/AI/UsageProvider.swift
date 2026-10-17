import Foundation

nonisolated enum UsageFailure: LocalizedError {
    case expired(String)
    case rejected(String)
    case http(Int)
    case unreadable(String, keys: [String])
    case credentialsUnreadable(String)

    var errorDescription: String? {
        switch self {
        case .expired(let name): "\(name) login expired. Run `\(name.lowercased())` once."
        case .rejected(let name): "\(name) refused the login. Run `\(name.lowercased())` once."
        case .http(let code): "The usage service answered with status \(code)."
        case .unreadable(let name, let keys): "The \(name) usage answer has an unknown format (fields: \(keys.isEmpty ? "none" : keys.joined(separator: ", ")))."
        case .credentialsUnreadable(let name): "The \(name) login could not be read."
        }
    }
}

nonisolated protocol UsageProviding: Sendable {
    func usage(for provider: UsageProviderID) async throws -> ProviderUsage?
}

nonisolated struct MockUsageProvider: UsageProviding {
    func usage(for provider: UsageProviderID) async throws -> ProviderUsage? {
        switch provider {
        case .claude:
            ProviderUsage(
                meters: [
                    UsageMeter(id: "five_hour", title: "Session", percent: 3, resetsAt: Date().addingTimeInterval(14_000), detail: nil),
                    UsageMeter(id: "seven_day", title: "Week · all", percent: 33, resetsAt: Date().addingTimeInterval(300_000), detail: nil)
                ],
                plan: "Max",
                note: nil
            )
        case .copilot:
            ProviderUsage(
                meters: [UsageMeter(id: "premium", title: "Premium requests", percent: 37, resetsAt: Date().addingTimeInterval(900_000), detail: "111 of 300 used")],
                plan: "Pro",
                note: nil
            )
        }
    }
}
