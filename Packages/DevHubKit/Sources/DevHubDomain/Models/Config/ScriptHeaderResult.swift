import Foundation

package struct ScriptHeaderResult: Hashable, Sendable {
    package var action: ActionConfig
    package var problems: [String]
    package var hasHeader: Bool

    package init(
        action: ActionConfig,
        problems: [String],
        hasHeader: Bool
    ) {
        self.action = action
        self.problems = problems
        self.hasHeader = hasHeader
    }
}
