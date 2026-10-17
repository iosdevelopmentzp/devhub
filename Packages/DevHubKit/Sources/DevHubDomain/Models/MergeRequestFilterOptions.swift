import Foundation

package struct MergeRequestFilterOptions: Hashable, Sendable {
    package let targetBranches: [String]
    package let labels: [String]

    package init(targetBranches: [String], labels: [String]) {
        self.targetBranches = targetBranches
        self.labels = labels
    }
}
