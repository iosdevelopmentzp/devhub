import Foundation

package struct ExplainPlan: Hashable, Sendable {
    package let parts: [[PullRequestFileDiff]]
    package let leftOut: [String]

    package init(parts: [[PullRequestFileDiff]], leftOut: [String]) {
        self.parts = parts
        self.leftOut = leftOut
    }
}
