import Foundation

nonisolated enum UsageProviderID: String, CaseIterable, Identifiable, Sendable {
    case claude
    case copilot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claude: "Claude"
        case .copilot: "Copilot"
        }
    }
}

nonisolated struct UsageMeter: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var percent: Double
    var resetsAt: Date?
    var detail: String?

    var clampedPercent: Double { min(max(percent, 0), 100) }
}

nonisolated struct ProviderUsage: Hashable, Sendable {
    var meters: [UsageMeter]
    var plan: String?
    var note: String?
}
