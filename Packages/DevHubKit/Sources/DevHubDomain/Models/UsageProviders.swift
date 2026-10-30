import Foundation

package enum UsageProviders: String, Codable, CaseIterable, Sendable {
    case all
    case claude
    case copilot

    package var includesClaude: Bool {
        self != .copilot
    }

    package var includesCopilot: Bool {
        self != .claude
    }
}
