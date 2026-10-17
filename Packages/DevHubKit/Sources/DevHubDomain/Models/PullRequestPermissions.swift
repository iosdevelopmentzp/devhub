import Foundation

package struct PullRequestPermissions: Hashable, Sendable {
    package static let none = PullRequestPermissions(canMerge: false, canApprove: false, canRevokeApproval: false, canSetAutoMerge: false)

    package let canMerge: Bool
    package let canApprove: Bool
    package let canRevokeApproval: Bool
    package let canSetAutoMerge: Bool

    package init(canMerge: Bool, canApprove: Bool, canRevokeApproval: Bool, canSetAutoMerge: Bool) {
        self.canMerge = canMerge
        self.canApprove = canApprove
        self.canRevokeApproval = canRevokeApproval
        self.canSetAutoMerge = canSetAutoMerge
    }
}
