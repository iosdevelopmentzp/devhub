import Foundation

package struct ActionItemContext: Hashable, Sendable {
    package var branch: String? = nil
    package var worktreePath: String? = nil
    package var simulatorUDID: String? = nil
    package var simulatorName: String? = nil
    package var bundleID: String? = nil
    package var rowID: String? = nil
    package var pullRequestNumber: Int? = nil
    package var pullRequestURL: URL? = nil
    package var refresh: [RefreshTarget] = []
    package var tabID: String? = nil
    package var inputs: [String: String] = [:]

    package static let none = ActionItemContext()

    package init(
        branch: String? = nil,
        worktreePath: String? = nil,
        simulatorUDID: String? = nil,
        simulatorName: String? = nil,
        bundleID: String? = nil,
        rowID: String? = nil,
        pullRequestNumber: Int? = nil,
        pullRequestURL: URL? = nil,
        refresh: [RefreshTarget] = [],
        tabID: String? = nil,
        inputs: [String: String] = [:]
    ) {
        self.branch = branch
        self.worktreePath = worktreePath
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
        self.bundleID = bundleID
        self.rowID = rowID
        self.pullRequestNumber = pullRequestNumber
        self.pullRequestURL = pullRequestURL
        self.refresh = refresh
        self.tabID = tabID
        self.inputs = inputs
    }
}
