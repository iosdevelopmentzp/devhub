import Foundation

package struct PullRequestPermissions: Hashable, Sendable {
    package static let none = PullRequestPermissions(canMerge: false, canApprove: false)

    package let canMerge: Bool
    package let canApprove: Bool

    package init(canMerge: Bool, canApprove: Bool) {
        self.canMerge = canMerge
        self.canApprove = canApprove
    }
}
