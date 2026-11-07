import Foundation

package enum UsageProviders: String, Codable, CaseIterable, Sendable {
    case all
    case claude
    case copilot
    case none

    package var includesClaude: Bool {
        self == .all || self == .claude
    }

    package var includesCopilot: Bool {
        self == .all || self == .copilot
    }
}
