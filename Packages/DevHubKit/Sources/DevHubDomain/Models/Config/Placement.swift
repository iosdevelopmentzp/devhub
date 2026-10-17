import Foundation

package struct Placement: Hashable, Codable, Sendable {
    package let rawValue: String

    package init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    package init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    package func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    package static let homeQuickActions = Placement("home.quickActions")
    package static let homeScripts = Placement("home.scripts")
    package static let gitPills = Placement("git.pills")
    package static let gitBranchRow = Placement("git.branchRow")
    package static let worktreesRow = Placement("worktrees.row")
    package static let simulatorsRunBar = Placement("simulators.runBar")
    package static let simulatorsRow = Placement("simulators.row")
    package static let logsToolbar = Placement("logs.toolbar")
    package static let palette = Placement("palette")

    package static func tab(_ id: String) -> Placement {
        Placement("tab.\(id)")
    }
}
